module Arkham.Location.Cards.RelicStorage (relicStorage, RelicStorage(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype RelicStorage = RelicStorage LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

relicStorage :: LocationCard RelicStorage
relicStorage = location RelicStorage Cards.relicStorage 5 (PerPlayer 1)

-- Card code: 54044b
-- Class: Mythos
-- Type: Location
-- Traits: [Lodge]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToForTheGreaterGood
-- Revealed Symbol: Trefoil
-- Revealed Connections: ['Moon']
-- Victory: 0
-- Unrevealed Card Id: 54044
-- Unrevealed Symbol: Trefoil
-- Unrevealed Connections: ['Moon']

-- Revealed Abilities:
-- While an investigator controls the [skull] key, Relic Storage is connected to Lodge Catacombs, and vice versa. <b>Forced</b> - After Relic Storage is revealed: Place 1 random set-aside key on it.
-- Unrevealed Abilities:
-- <b>Forced</b> - When you enter Hidden Passageway: Test [agility] (3). If you fail, place 1 doom on the nearest [[Cultist]] enemy as they hear you shifting the bookcase.
-- TODO Card Text:


instance HasAbilities RelicStorage where
  getAbilities (RelicStorage attrs) = extendRevealed attrs []

instance RunMessage RelicStorage where
  runMessage msg l@(RelicStorage attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> RelicStorage <$> liftRunMessage msg attrs
