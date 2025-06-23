module Arkham.Location.Cards.ShroudedArchive (shroudedArchive, ShroudedArchive(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype ShroudedArchive = ShroudedArchive LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

shroudedArchive :: LocationCard ShroudedArchive
shroudedArchive = location ShroudedArchive Cards.shroudedArchive 4 (Static 0)

-- Card code: 54045b
-- Class: Mythos
-- Type: Location
-- Traits: [Lodge, Sanctum]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToForTheGreaterGood
-- Revealed Symbol: Star
-- Revealed Connections: ['Squiggle']
-- Victory: 
-- Unrevealed Card Id: 54045
-- Unrevealed Symbol: Star
-- Unrevealed Connections: ['Squiggle']

-- Revealed Abilities:
-- [action]: Choose a ([skull]/[cultist]/[tablet]/[elder_thing]) key on a card and test [willpower] or [intellect] (8). Reduce the difficulty of this test by 1 for each [[Silver Twilight]] enemy in play. If you succeed, swap the chosen key with another key in play or with a set-aside ([skull]/[cultist]/[tablet]/[elder_thing]) key.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities ShroudedArchive where
  getAbilities (ShroudedArchive attrs) = extendRevealed attrs []

instance RunMessage ShroudedArchive where
  runMessage msg l@(ShroudedArchive attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> ShroudedArchive <$> liftRunMessage msg attrs
