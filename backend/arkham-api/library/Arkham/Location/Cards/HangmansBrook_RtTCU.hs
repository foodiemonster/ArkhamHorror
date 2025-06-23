module Arkham.Location.Cards.HangmansBrook (hangmansBrook, HangmansBrook(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype HangmansBrook = HangmansBrook LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

hangmansBrook :: LocationCard HangmansBrook
hangmansBrook = location HangmansBrook Cards.hangmansBrook 3 (PerPlayer 1)

-- Card code: 54037b
-- Class: Mythos
-- Type: Location
-- Traits: []
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheWagesOfSin
-- Revealed Symbol: Squiggle
-- Revealed Connections: ['Circle', 'Triangle']
-- Victory: 0
-- Unrevealed Card Id: 54037
-- Unrevealed Symbol: Squiggle
-- Unrevealed Connections: ['Circle', 'Triangle']

-- Revealed Abilities:
-- [action]: --Resign.</b> "Whose bright idea was this, anyway?"
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities HangmansBrook where
  getAbilities (HangmansBrook attrs) = extendRevealed attrs []

instance RunMessage HangmansBrook where
  runMessage msg l@(HangmansBrook attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> HangmansBrook <$> liftRunMessage msg attrs
