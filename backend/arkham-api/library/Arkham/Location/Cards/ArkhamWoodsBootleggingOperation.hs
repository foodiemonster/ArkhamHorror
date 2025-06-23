module Arkham.Location.Cards.ArkhamWoodsBootleggingOperation (arkhamWoodsBootleggingOperation, ArkhamWoodsBootleggingOperation(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype ArkhamWoodsBootleggingOperation = ArkhamWoodsBootleggingOperation LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

arkhamWoodsBootleggingOperation :: LocationCard ArkhamWoodsBootleggingOperation
arkhamWoodsBootleggingOperation = location ArkhamWoodsBootleggingOperation Cards.arkhamWoodsBootleggingOperation 1 (PerPlayer 1)

-- Card code: 54023b
-- Class: Mythos
-- Type: Location
-- Traits: [Woods]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToTheWitchingHour
-- Revealed Symbol: Moon
-- Revealed Connections: ['Squiggle', 'Equals', 'Hourglass']
-- Victory: 0
-- Unrevealed Card Id: 54023
-- Unrevealed Symbol: Squiggle
-- Unrevealed Connections: ['Squiggle', 'Plus']

-- Revealed Abilities:
-- <b>Forced</b> - After you successfully investigate this location: Discard 1 card from the top of the encounter deck for each point you succeeded by. --Forced</b> - When the encounter deck runs out of cards: Each investigator at this location takes 2 damage.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities ArkhamWoodsBootleggingOperation where
  getAbilities (ArkhamWoodsBootleggingOperation attrs) = extendRevealed attrs []

instance RunMessage ArkhamWoodsBootleggingOperation where
  runMessage msg l@(ArkhamWoodsBootleggingOperation attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> ArkhamWoodsBootleggingOperation <$> liftRunMessage msg attrs
