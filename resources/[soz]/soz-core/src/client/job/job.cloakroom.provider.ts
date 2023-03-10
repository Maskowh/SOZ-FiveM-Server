import { WardrobeConfig } from '@public/shared/cloth';
import { HAZMAT_OUTFIT_NAME, LsmcCloakroom } from '@public/shared/job/lsmc';

import { OnEvent } from '../../core/decorators/event';
import { Inject } from '../../core/decorators/injectable';
import { Provider } from '../../core/decorators/provider';
import { emitRpc } from '../../core/rpc';
import { ClientEvent, ServerEvent } from '../../shared/event';
import { RpcEvent } from '../../shared/rpc';
import { InventoryManager } from '../inventory/inventory.manager';
import { Notifier } from '../notifier';
import { PlayerService } from '../player/player.service';
import { PlayerWardrobe } from '../player/player.wardrobe';
import { ProgressService } from '../progress.service';

@Provider()
export class JobCloakroomProvider {
    @Inject(Notifier)
    private notifier: Notifier;

    @Inject(PlayerService)
    private playerService: PlayerService;

    @Inject(InventoryManager)
    private inventoryManager: InventoryManager;

    @Inject(ProgressService)
    private progressService: ProgressService;

    @Inject(PlayerWardrobe)
    private playerWardrobe: PlayerWardrobe;

    @OnEvent(ClientEvent.JOBS_TRY_OPEN_CLOAKROOM)
    public async onTryOpenCloakroom(storageId: string, event: string) {
        const result = await emitRpc(RpcEvent.INVENTORY_SEARCH, storageId, 'work_clothes');
        if (!result) {
            this.notifier.notify(`Il n'y a pas de tenue de travail dans le vestiaire.`, 'error');
            return;
        }

        // Keep propagating the storageId as we need to remove a work_clothes item
        // from it only when selecting the appropriate button on the cloakroom menu.
        TriggerEvent(event, storageId);
    }

    @OnEvent(ClientEvent.JOBS_CHECK_CLOAKROOM_STORAGE)
    public async onCheckCloakroomStorage(storageId: string) {
        const { completed } = await this.progressService.progress(
            'check-cloakroom',
            'Vérification du vestiaire',
            5000,
            {
                name: 'think_01_amy_skater_01',
                dictionary: 'anim@amb@board_room@whiteboard@',
                flags: 1,
            }
        );
        if (!completed) {
            return;
        }
        const result = await emitRpc(RpcEvent.INVENTORY_SEARCH, storageId, 'work_clothes');
        if (!result) {
            this.notifier.notify(`Il n'y a pas de tenue de travail dans le vestiaire.`, 'error');
            return;
        }
        this.notifier.notify(`Il reste ${result} tenues de travail dans le vestiaire.`);
    }

    public async openCloakroom(storageIdToSave: string, config: WardrobeConfig, customLabel?: string) {
        const outfitSelection = await this.playerWardrobe.selectOutfit(config, 'Tenue civile', customLabel);

        if (outfitSelection.canceled) {
            return;
        }

        const progress = await this.playerWardrobe.waitProgress(false);

        if (!progress.completed) {
            return;
        }

        if (outfitSelection.outfit) {
            if (storageIdToSave) {
                TriggerServerEvent(ServerEvent.JOBS_USE_WORK_CLOTHES, storageIdToSave);
            }

            TriggerServerEvent(ServerEvent.CHARACTER_SET_JOB_CLOTHES, outfitSelection.outfit);

            const ped = PlayerPedId();
            let hazmat = true;
            for (const [id, component] of Object.entries(
                LsmcCloakroom[GetEntityModel(ped)][HAZMAT_OUTFIT_NAME].Components
            )) {
                if (
                    !outfitSelection.outfit.Components[id] ||
                    outfitSelection.outfit.Components[id].drawable != component.Drawable
                ) {
                    hazmat = false;
                    break;
                }
            }
            TriggerServerEvent('lsmc:server:SetHazmat', hazmat);
        } else {
            TriggerServerEvent(ServerEvent.CHARACTER_SET_JOB_CLOTHES, null);
        }
    }
}
