module Arkham.Location.Cards.ArkhamWoodsPlaceOfPower (arkhamWoodsPlaceOfPower, ArkhamWoodsPlaceOfPower(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype ArkhamWoodsPlaceOfPower = ArkhamWoodsPlaceOfPower LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arkhamWoodsPlaceOfPower :: LocationCard ArkhamWoodsPlaceOfPower
arkhamWoodsPlaceOfPower = location ArkhamWoodsPlaceOfPower Cards.arkhamWoodsPlaceOfPower 3 (PerPlayer 1)

-- Card code: 54022b
-- Class: Mythos
-- Type: Location
-- Traits: [Woods]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheWitchingHour
-- Revealed Symbol: Trefoil
-- Revealed Connections: ['Squiggle', 'Spade']
-- Victory: 0
-- Unrevealed Card Id: 54022
-- Unrevealed Symbol: Squiggle
-- Unrevealed Connections: ['Squiggle', 'Plus']

-- Revealed Abilities:
-- While you are at this location, you cannot cancel or ignore card or game effects, and each encounter card you draw gains peril.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities ArkhamWoodsPlaceOfPower where
  getAbilities (ArkhamWoodsPlaceOfPower attrs) = extendRevealed attrs []

instance RunMessage ArkhamWoodsPlaceOfPower where
  runMessage msg l@(ArkhamWoodsPlaceOfPower attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> ArkhamWoodsPlaceOfPower <$> liftRunMessage msg attrs
