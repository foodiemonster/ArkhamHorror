module Arkham.Location.Cards.ThePriceManor (thePriceManor, ThePriceManor(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype ThePriceManor = ThePriceManor LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

thePriceManor :: LocationCard ThePriceManor
thePriceManor = location ThePriceManor Cards.thePriceManor 2 (PerPlayer 1)

-- Card code: 54031b
-- Class: Mythos
-- Type: Location
-- Traits: [Extradimensional]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheSecretName
-- Revealed Symbol: Moon
-- Revealed Connections: ['Square']
-- Victory: 0
-- Unrevealed Card Id: 54031
-- Unrevealed Symbol: Moon
-- Unrevealed Connections: ['Square']

-- Revealed Abilities:
-- [action]: Test [combat] (5) to topple the strange, eldritch statue. If you succeed, remove 1 doom from Nahab, even if she is out of play. (Group limit one success per game.) --Haunted</b> - Place 1 doom on Nahab (even if she is out of play).
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities ThePriceManor where
  getAbilities (ThePriceManor attrs) = extendRevealed attrs []

instance RunMessage ThePriceManor where
  runMessage msg l@(ThePriceManor attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> ThePriceManor <$> liftRunMessage msg attrs
