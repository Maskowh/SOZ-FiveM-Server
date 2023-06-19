import { Injectable } from '@core/decorators/injectable';

@Injectable()
export class PlayerInjuryProvider {
    public hasMaxInjuries(): boolean {
        return false;
    }
}
