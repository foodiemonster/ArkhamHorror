module Arkham.Location.Cards.ArkhamWoodsHiddenPath (arkhamWoodsHiddenPath, ArkhamWoodsHiddenPath(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype ArkhamWoodsHiddenPath = ArkhamWoodsHiddenPath LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arkhamWoodsHiddenPath :: LocationCard ArkhamWoodsHiddenPath
arkhamWoodsHiddenPath = location ArkhamWoodsHiddenPath Cards.arkhamWoodsHiddenPath 2 (PerPlayer 1)

-- Card code: 54021b
-- Class: Mythos
-- Type: Location
-- Traits: [Woods]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheWitchingHour
-- Revealed Symbol: Spade
-- Revealed Connections: ['Squiggle', 'Trefoil']
-- Victory: 0
-- Unrevealed Card Id: 54021
-- Unrevealed Symbol: Squiggle
-- Unrevealed Connections: ['Squiggle', 'Plus']

-- Revealed Abilities:
-- During the "enemy attacks" step of the enemy phase, instead of their standard attack, each ready [[Witch]] enemy at this location attacks each investigator in play. Attacks made in this way do not cause the enemy to exhaust.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities ArkhamWoodsHiddenPath where
  getAbilities (ArkhamWoodsHiddenPath attrs) = extendRevealed attrs []

instance RunMessage ArkhamWoodsHiddenPath where
  runMessage msg l@(ArkhamWoodsHiddenPath attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> ArkhamWoodsHiddenPath <$> liftRunMessage msg attrs
