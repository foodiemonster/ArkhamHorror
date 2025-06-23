module Arkham.Location.Cards.NightmareBreach (nightmareBreach, NightmareBreach(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype NightmareBreach = NightmareBreach LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

nightmareBreach :: LocationCard NightmareBreach
nightmareBreach = location NightmareBreach Cards.nightmareBreach 5 (Static 1)

-- Card code: 54058b
-- Class: Mythos
-- Type: Location
-- Traits: [Otherworld, Void]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToBeforeTheBlackThrone
-- Revealed Symbol: Nosymbol
-- Revealed Connections: ['Nosymbol']
-- Victory: 0
-- Unrevealed Card Id: 54058
-- Unrevealed Symbol: Nosymbol
-- Unrevealed Connections: ['Nosymbol']

-- Revealed Abilities:
-- <b>Cosmos</b> - Connect in a direction of your choice, but only onto a spot where an empty space exists. Remove that empty space from the game instead of shuffling it back into its owner's deck. Then, discard each other copy of that card from play and from each investigator's hand.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities NightmareBreach where
  getAbilities (NightmareBreach attrs) = extendRevealed attrs []

instance RunMessage NightmareBreach where
  runMessage msg l@(NightmareBreach attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> NightmareBreach <$> liftRunMessage msg attrs
