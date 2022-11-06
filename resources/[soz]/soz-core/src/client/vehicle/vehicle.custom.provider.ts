import { Once, OnceStep, OnNuiEvent } from '../../core/decorators/event';
import { Inject } from '../../core/decorators/injectable';
import { Provider } from '../../core/decorators/provider';
import { emitRpc } from '../../core/rpc';
import { NuiEvent } from '../../shared/event';
import { MenuType } from '../../shared/nui/menu';
import { BoxZone } from '../../shared/polyzone/box.zone';
import { MultiZone } from '../../shared/polyzone/multi.zone';
import { Vector3 } from '../../shared/polyzone/vector';
import { RpcEvent } from '../../shared/rpc';
import {
    getVehicleCustomPrice,
    VehicleConfiguration,
    VehicleCustomMenuData,
    VehicleUpgradeOptions,
} from '../../shared/vehicle/modification';
import { BlipFactory } from '../blip';
import { Notifier } from '../notifier';
import { NuiMenu } from '../nui/nui.menu';
import { PlayerService } from '../player/player.service';
import { VehicleRepository } from '../resources/vehicle.repository';
import { TargetFactory } from '../target/target.factory';
import { VehicleModificationService } from './vehicle.modification.service';
import { VehicleService } from './vehicle.service';

@Provider()
export class VehicleCustomProvider {
    @Inject(PlayerService)
    private playerService: PlayerService;

    @Inject(TargetFactory)
    private targetFactory: TargetFactory;

    @Inject(BlipFactory)
    private blipFactory: BlipFactory;

    @Inject(VehicleRepository)
    private vehicleRepository: VehicleRepository;

    @Inject(VehicleService)
    private vehicleService: VehicleService;

    @Inject(Notifier)
    private notifier: Notifier;

    @Inject(NuiMenu)
    private nuiMenu: NuiMenu;

    @Inject(VehicleModificationService)
    private vehicleModificationService: VehicleModificationService;

    private lsCustomZone = new MultiZone([
        new BoxZone([-339.46, -136.73, 39.01], 10, 10, {
            heading: 70,
            minZ: 38.01,
            maxZ: 42.01,
        }),
        new BoxZone([-1154.88, -2005.4, 13.18], 10, 10, {
            heading: 45,
            minZ: 12.18,
            maxZ: 16.18,
        }),
        new BoxZone([731.87, -1087.88, 22.17], 10, 10, {
            heading: 0,
            minZ: 21.17,
            maxZ: 25.17,
        }),
        new BoxZone([110.98, 6627.06, 31.89], 10, 10, {
            heading: 45,
            minZ: 30.89,
            maxZ: 34.89,
        }),
        new BoxZone([1175.88, 2640.3, 37.79], 10, 10, {
            heading: 45,
            minZ: 36.79,
            maxZ: 40.79,
        }),
    ]);

    @Once(OnceStep.PlayerLoaded)
    onStart(): void {
        for (const zoneIndex in this.lsCustomZone.zones) {
            const zone = this.lsCustomZone.zones[zoneIndex];

            this.blipFactory.create(`ls_custom_${zoneIndex}`, {
                sprite: 72,
                color: 46,
                coords: {
                    x: zone.center[0],
                    y: zone.center[1],
                    z: zone.center[2],
                },
                name: 'LS Custom',
            });
        }

        this.targetFactory.createForAllVehicle([
            {
                icon: 'c:mechanic/Ameliorer.png',
                label: 'Améliorer sa voiture',
                blackoutGlobal: true,
                action: vehicle => {
                    this.upgradeVehicle(vehicle);
                },
                canInteract: () => {
                    const position = GetEntityCoords(PlayerPedId(), true) as Vector3;

                    return this.lsCustomZone.isPointInside(position);
                },
            },
        ]);
    }

    @OnNuiEvent<{ menuType: MenuType; menuData: VehicleCustomMenuData }>(NuiEvent.MenuClosed)
    public async onMenuClose({ menuType, menuData }) {
        if (menuType !== MenuType.VehicleCustom) {
            return;
        }

        const vehicleNetworkId = NetworkGetNetworkIdFromEntity(menuData.vehicle);
        const vehicleCurrentConfiguration = await emitRpc<VehicleConfiguration>(
            RpcEvent.VEHICLE_CUSTOM_GET_MODS,
            vehicleNetworkId
        );

        this.vehicleModificationService.applyVehicleConfiguration(menuData.vehicle, vehicleCurrentConfiguration);
    }

    @OnNuiEvent<{ vehicleEntityId: number; vehicleConfiguration: VehicleConfiguration }>(NuiEvent.VehicleCustomApply)
    public async applyVehicleConfiguration({ vehicleEntityId, vehicleConfiguration }): Promise<VehicleUpgradeOptions> {
        this.vehicleModificationService.applyVehicleConfiguration(vehicleEntityId, vehicleConfiguration);

        return this.vehicleModificationService.createOptions(vehicleEntityId);
    }

    @OnNuiEvent<{ vehicleEntityId: number; vehicleConfiguration: Partial<VehicleConfiguration> }>(
        NuiEvent.VehicleCustomConfirmModification
    )
    public async confirmVehicleCustom({ vehicleEntityId, vehicleConfiguration, usePricing }): Promise<void> {
        const options = this.vehicleModificationService.createOptions(vehicleEntityId);
        const vehicle = this.vehicleRepository.getByModelHash(GetEntityModel(vehicleEntityId));

        const vehicleNetworkId = NetworkGetNetworkIdFromEntity(vehicleEntityId);
        const vehicleCurrentConfiguration = await emitRpc<VehicleConfiguration>(
            RpcEvent.VEHICLE_CUSTOM_GET_MODS,
            vehicleNetworkId
        );

        let price = 0;

        if (usePricing && vehicle) {
            price = getVehicleCustomPrice(vehicle.price, options, vehicleCurrentConfiguration, vehicleConfiguration);
        }

        const newVehicleConfiguration = await emitRpc<VehicleConfiguration>(
            RpcEvent.VEHICLE_CUSTOM_SET_MODS,
            vehicleNetworkId,
            vehicleConfiguration,
            price
        );

        this.vehicleService.applyVehicleConfiguration(vehicleEntityId, newVehicleConfiguration);
        this.nuiMenu.closeMenu();
    }

    public async upgradeVehicle(vehicleEntityId: number) {
        const options = this.vehicleModificationService.createOptions(vehicleEntityId);
        const vehicle = this.vehicleRepository.getByModelHash(GetEntityModel(vehicleEntityId));

        if (!vehicle) {
            this.notifier.notify(
                "Cette voiture n'est pas enregistré auprès des autorités et ne peut donc pas être modifiée, veuillez prendre contact avec les autorités.",
                'error'
            );

            return;
        }

        const vehicleConfiguration = await this.vehicleService.getVehicleConfiguration(vehicleEntityId);

        this.nuiMenu.openMenu(MenuType.VehicleCustom, {
            vehicle: vehicleEntityId,
            vehiclePrice: vehicle.price,
            options,
            currentConfiguration: vehicleConfiguration,
        });
    }
}
