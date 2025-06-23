module Arkham.Location.Cards.WindingGulf (windingGulf, WindingGulf(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype WindingGulf = WindingGulf LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

windingGulf :: LocationCard WindingGulf
windingGulf = location WindingGulf Cards.windingGulf 2 (Static 2)

-- Card code: 54060b
-- Class: Mythos
-- Type: Location
-- Traits: [Otherworld, Void]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToBeforeTheBlackThrone
-- Revealed Symbol: Nosymbol
-- Revealed Connections: ['Nosymbol']
-- Victory: 0
-- Unrevealed Card Id: 54060
-- Unrevealed Symbol: Nosymbol
-- Unrevealed Connections: ['Nosymbol']

-- Revealed Abilities:
-- <b>Cosmos</b> - Connect to the leftmost revealed location in a direction of your choice. You may choose not to move to Winding Gulf and instead place 1 doom on Azathoth. <b>Haunted</b> - Take 1 damage and 1 horror.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities WindingGulf where
  getAbilities (WindingGulf attrs) = extendRevealed attrs []

instance RunMessage WindingGulf where
  runMessage msg l@(WindingGulf attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> WindingGulf <$> liftRunMessage msg attrs
