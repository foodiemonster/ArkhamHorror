module Arkham.Location.Cards.InterstellarAbyss (interstellarAbyss, InterstellarAbyss(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype InterstellarAbyss = InterstellarAbyss LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

interstellarAbyss :: LocationCard InterstellarAbyss
interstellarAbyss = location InterstellarAbyss Cards.interstellarAbyss 6 (Static 0)

-- Card code: 54059b
-- Class: Mythos
-- Type: Location
-- Traits: [Otherworld, Void]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToBeforeTheBlackThrone
-- Revealed Symbol: Nosymbol
-- Revealed Connections: ['Nosymbol']
-- Victory: 0
-- Unrevealed Card Id: 54059
-- Unrevealed Symbol: Nosymbol
-- Unrevealed Connections: ['Nosymbol']

-- Revealed Abilities:
-- <b>Cosmos</b> - Connect in the direction nearest to The Black Throne (or any direction if The Black Throne is not in play). While you are at Interstellar Abyss, you cannot spend clues.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities InterstellarAbyss where
  getAbilities (InterstellarAbyss attrs) = extendRevealed attrs []

instance RunMessage InterstellarAbyss where
  runMessage msg l@(InterstellarAbyss attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> InterstellarAbyss <$> liftRunMessage msg attrs
