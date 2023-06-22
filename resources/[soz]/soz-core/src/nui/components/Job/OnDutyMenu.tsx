import { FunctionComponent } from 'react';

import { MenuType } from '../../../shared/nui/menu';
import { MainMenu, Menu, MenuContent, MenuItemText, MenuTitle } from '../Styleguide/Menu';

export const JobOnDutyMenu: FunctionComponent<any> = ({ data }) => {
    const banner = `https://nui-img/soz/menu_job_${data.job}`;

    if (!data.state.length) {
        return null;
    }

    return (
        <Menu type={MenuType.JobOnDutyMenu}>
            <MainMenu>
                <MenuTitle banner={banner}>Employé(e)s en service</MenuTitle>
                <MenuContent>
                    {Object.values(data.state).map(player_name => (
                        <MenuItemText>{player_name}</MenuItemText>
                    ))}
                </MenuContent>
            </MainMenu>
        </Menu>
    );
};
