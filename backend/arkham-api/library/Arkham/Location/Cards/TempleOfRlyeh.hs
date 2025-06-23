module Arkham.Location.Cards.TempleOfRlyeh (templeOfRlyeh, TempleOfRlyeh(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype TempleOfRlyeh = TempleOfRlyeh LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

templeOfRlyeh :: LocationCard TempleOfRlyeh
templeOfRlyeh = location TempleOfRlyeh Cards.templeOfRlyeh 3 (PerPlayer 2)

-- Card code: 54030b
-- Class: Mythos
-- Type: Location
-- Traits: [Extradimensional, Otherworld]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheSecretName
-- Revealed Symbol: Equals
-- Revealed Connections: ['Squiggle', 'Square']
-- Victory: 1
-- Unrevealed Card Id: 54030
-- Unrevealed Symbol: Moon
-- Unrevealed Connections: ['Square']

-- Revealed Abilities:
-- --Forced</b> - After you reveal Temple of R'lyeh: Test [willpower] (3). If you fail, draw the top card of the encounter deck. If you fail by 3 or more, that card gains surge.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities TempleOfRlyeh where
  getAbilities (TempleOfRlyeh attrs) = extendRevealed attrs []

instance RunMessage TempleOfRlyeh where
  runMessage msg l@(TempleOfRlyeh attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> TempleOfRlyeh <$> liftRunMessage msg attrs
