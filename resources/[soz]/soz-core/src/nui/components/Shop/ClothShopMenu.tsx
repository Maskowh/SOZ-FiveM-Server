import { useNuiEvent } from '@public/nui/hook/nui';
import { PlayerData } from '@public/shared/player';
import { ClothingShop, ClothingShopCategory, ClothingShopItem } from '@public/shared/shop';
import { FunctionComponent, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

import { NuiEvent } from '../../../shared/event';
import { MenuType } from '../../../shared/nui/menu';
import { fetchNui } from '../../fetch';
import {
    MainMenu,
    Menu,
    MenuContent,
    MenuItemButton,
    MenuItemSelect,
    MenuItemSelectOption,
    MenuTitle,
    SubMenu,
} from '../Styleguide/Menu';

type MenuClothShopStateProps = {
    catalog: {
        brand: string;
        shop_content: ClothingShop;
        shop_categories: Record<number, ClothingShopCategory>;
        player_data: PlayerData;
    };
};

export const ClothShopMenu: FunctionComponent<MenuClothShopStateProps> = ({ catalog }) => {
    const banner =
        catalog.brand == 'ponsonbys'
            ? 'https://nui-img/soz/menu_shop_clothe_luxe'
            : 'https://nui-img/soz/menu_shop_clothe_normal';
    const navigate = useNavigate();
    const location = useLocation();
    const state = location.state as { activeIndex: number } | undefined;
    const [stocks, setStocks] = useState<Record<number, number>>(catalog.shop_content.stocks);
    const [playerData, setPlayerData] = useState<PlayerData>(catalog.player_data);

    const selectCategory = (categoryId: number) => {
        navigate(`/${MenuType.ClothShop}/${categoryId}`, {
            state: {
                ...(state || {}),
                activeIndex: 0,
            },
        });
    };

    useNuiEvent('menu', 'Backspace', () => {
        fetchNui(NuiEvent.ClothingShopBackspace);
    });

    useNuiEvent('cloth_shop', 'SetStocks', stocks => {
        setStocks(stocks);
    });

    useNuiEvent('cloth_shop', 'SetPlayerData', playerData => {
        setPlayerData(playerData);
    });

    return (
        <Menu type={MenuType.ClothShop}>
            <MainMenu>
                <MenuTitle banner={banner}>
                    Magasin {catalog.brand.charAt(0).toUpperCase() + catalog.brand.slice(1)}
                </MenuTitle>
                <MenuContent>
                    {Object.values(catalog.shop_content.categories)
                        .filter(
                            category =>
                                catalog.shop_categories[category.id].content.length > 0 ||
                                Object.values(catalog.shop_categories).filter(
                                    childCat => childCat.parentId == category.id
                                ).length > 0
                        )
                        .map(category => (
                            <MenuItemButton
                                key={category.id}
                                onConfirm={async () => {
                                    selectCategory(category.id);
                                }}
                            >
                                {category.name}
                            </MenuItemButton>
                        ))}
                </MenuContent>
            </MainMenu>
            {Object.values(catalog.shop_categories).map(cat => {
                const items = cat.content
                    .filter(
                        product =>
                            !product.undershirtType ||
                            (playerData.cloth_config.BaseClothSet.underTypes != null &&
                                playerData.cloth_config.BaseClothSet.underTypes.includes(product.undershirtType)) // Compatible undershirt types
                    )
                    .sort((a, b) => a.label.localeCompare(b.label));
                if (items.length == 0 || !items[0].modelLabel) {
                    // Return legacy display
                    return (
                        <SubMenu key={cat.id} id={String(cat.id)}>
                            <MenuTitle banner={banner}>{cat.name}</MenuTitle>
                            <MenuContent>
                                {Object.values(catalog.shop_categories)
                                    .filter(
                                        childCat =>
                                            // Check if this subcategory is not empty and is a child of this category
                                            childCat.parentId == cat.id &&
                                            (Object.values(catalog.shop_categories).filter(
                                                childchildCat => childchildCat.parentId == childCat.id
                                            ).length > 0 ||
                                                childCat.content.filter(
                                                    product =>
                                                        !product.undershirtType ||
                                                        (playerData.cloth_config.BaseClothSet.underTypes != null &&
                                                            playerData.cloth_config.BaseClothSet.underTypes.includes(
                                                                product.undershirtType
                                                            )) // Compatible undershirt types
                                                ).length > 0)
                                    )
                                    .map(childCat => (
                                        <MenuItemButton
                                            key={childCat.id}
                                            onConfirm={async () => {
                                                selectCategory(childCat.id);
                                                fetchNui(NuiEvent.ClothingShopBackspace);
                                            }}
                                        >
                                            {childCat.name}
                                        </MenuItemButton>
                                    ))}
                                {items.map(product => {
                                    // Legacy displaying
                                    let description = "Ce produit n'est plus en stock.";
                                    if (stocks[product.id] == 1) {
                                        description = "C'est le dernier produit en stock !";
                                    } else {
                                        description = `Il reste ${stocks[product.id]} produits en stock.`;
                                    }
                                    return (
                                        <MenuItemButton
                                            key={product.id}
                                            disabled={stocks[product.id] === 0}
                                            onSelected={async () =>
                                                await fetchNui(NuiEvent.ClothingShopPreview, product)
                                            }
                                            onConfirm={async () => await fetchNui(NuiEvent.ClothingShopBuy, product)}
                                            description={description}
                                        >
                                            <div className="flex justify-between items-center">
                                                <span>{product.label}</span>
                                                <span className="mr-1">${product.price}</span>
                                            </div>
                                        </MenuItemButton>
                                    );
                                })}
                            </MenuContent>
                        </SubMenu>
                    );
                } else {
                    // Group by modelLabels
                    const groupedItems: Record<string, ClothingShopItem[]> = {};
                    items.forEach(item => {
                        if (!groupedItems[item.modelLabel]) {
                            groupedItems[item.modelLabel] = [];
                        }
                        groupedItems[item.modelLabel].push(item);
                    });
                    // Return new display
                    return (
                        <SubMenu key={cat.id} id={String(cat.id)}>
                            <MenuTitle banner={banner}>{cat.name}</MenuTitle>
                            <MenuContent>
                                {Object.values(catalog.shop_categories)
                                    .filter(
                                        childCat =>
                                            // is child
                                            childCat.parentId == cat.id &&
                                            // has sub category
                                            (Object.values(catalog.shop_categories).filter(
                                                childchildCat => childchildCat.parentId == childCat.id
                                            ).length > 0 || // or has items
                                                childCat.content.filter(
                                                    product =>
                                                        !product.undershirtType ||
                                                        (playerData.cloth_config.BaseClothSet.underTypes != null &&
                                                            playerData.cloth_config.BaseClothSet.underTypes.includes(
                                                                product.undershirtType
                                                            ))
                                                ).length > 0)
                                    )
                                    .map(childCat => (
                                        <MenuItemButton
                                            key={childCat.id}
                                            onConfirm={async () => {
                                                selectCategory(childCat.id);
                                                fetchNui(NuiEvent.ClothingShopBackspace);
                                            }}
                                        >
                                            {childCat.name}
                                        </MenuItemButton>
                                    ))}
                                {Object.entries(groupedItems).map(([modelLabel, items]) => (
                                    <MenuItemSelect
                                        keyDescendant={modelLabel}
                                        title={modelLabel}
                                        titleWidth={60}
                                        value={items[0]}
                                        initialValue={items[0]}
                                        onChange={async (_, item) => await fetchNui(NuiEvent.ClothingShopPreview, item)}
                                        onConfirm={async (_, item) => await fetchNui(NuiEvent.ClothingShopBuy, item)}
                                        onSelectedValue={async (_, item) =>
                                            await fetchNui(NuiEvent.ClothingShopPreview, item)
                                        }
                                        descriptionValue={item => `Il reste ${stocks[item.id]} produits en stock.`}
                                    >
                                        {items.map(item => (
                                            <MenuItemSelectOption
                                                key={item.id}
                                                value={item}
                                                description={`Il reste ${stocks[item.id]} produits en stock.`}
                                                disabled={stocks[item.id] == 0}
                                            >
                                                {item.colorLabel}
                                            </MenuItemSelectOption>
                                        ))}
                                    </MenuItemSelect>
                                ))}
                            </MenuContent>
                        </SubMenu>
                    );
                }
            })}
        </Menu>
    );
};
