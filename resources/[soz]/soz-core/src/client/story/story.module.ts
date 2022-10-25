import { Module } from '../../core/decorators/module';
import { Halloween2022Scenario1Provider } from './halloween-2022/scenario1.provider';
import { Halloween2022Scenario2Provider } from './halloween-2022/scenario2.provider';
import { StoryProvider } from './story.provider';

@Module({
    providers: [StoryProvider, Halloween2022Scenario1Provider, Halloween2022Scenario2Provider],
})
export class StoryModule {}
