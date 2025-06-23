module Arkham.Location.Cards.HangmansBrookSpectral (hangmansBrookSpectral, HangmansBrookSpectral(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype HangmansBrookSpectral = HangmansBrookSpectral LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

hangmansBrookSpectral :: LocationCard HangmansBrookSpectral
hangmansBrookSpectral = location HangmansBrookSpectral Cards.hangmansBrookSpectral 3 (Static 0)

-- Card code: 54037
-- Class: Mythos
-- Type: Location
-- Traits: [Spectral]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheWagesOfSin
-- Revealed Symbol: Squiggle
-- Revealed Connections: ['Circle', 'Triangle']
-- Victory: 0
-- Unrevealed Card Id: 54037
-- Unrevealed Symbol: Squiggle
-- Unrevealed Connections: ['Circle', 'Triangle']

-- Revealed Abilities:
-- [action]: --Resign.</b> "Whose bright idea was this, anyway?" --Haunted</b> - Place 1 clue from the supply on Hangman's Brook.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities HangmansBrookSpectral where
  getAbilities (HangmansBrookSpectral attrs) = extendRevealed attrs []

instance RunMessage HangmansBrookSpectral where
  runMessage msg l@(HangmansBrookSpectral attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> HangmansBrookSpectral <$> liftRunMessage msg attrs
