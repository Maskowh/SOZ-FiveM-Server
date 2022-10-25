import { AdminMenuStateProps } from '../../nui/components/Admin/AdminMenu';
import { WardrobeMenuData } from '../cloth';
import { GarageMenuData } from '../vehicle/garage';
import { VehicleMenuData } from '../vehicle/vehicle';

export interface NuiMenuMethodMap {
    ArrowDown: never;
    ArrowLeft: never;
    ArrowRight: never;
    ArrowUp: never;
    Backspace: never;
    CloseMenu: never;
    Enter: never;
    SetMenuType: SetMenuType;
}

export type SetMenuType = {
    menuType: MenuType;
    data: any;
    subMenuId?: string;
};

export enum MenuType {
    AdminMenu = 'AdminMenu',
    BahamaUnicornJobMenu = 'baun_job',
    BennysOrderMenu = 'bennys_order',
    Demo = 'demo',
    BossShop = 'boss_shop',
    MaskShop = 'mask_shop',
    FightForStyleJobMenu = 'ffs_job',
    FoodJobMenu = 'food_job_menu',
    Garage = 'garage_menu',
    SetHealthState = 'set_health_state',
    StonkJobMenu = 'stonk_job',
    Vehicle = 'vehicle',
    VehicleCustom = 'vehicle_custom',
    VehicleDealership = 'vehicle_dealership',
    Wardrobe = 'wardrobe',
}

export interface MenuTypeMap extends Record<MenuType, unknown> {
    [MenuType.AdminMenu]: AdminMenuStateProps['data'];
    [MenuType.BahamaUnicornJobMenu]: any;
    [MenuType.FightForStyleJobMenu]: any;
    [MenuType.Demo]: never;
    [MenuType.SetHealthState]: number;
    [MenuType.Wardrobe]: WardrobeMenuData;
    [MenuType.Vehicle]: VehicleMenuData;
    [MenuType.Garage]: GarageMenuData;
}
