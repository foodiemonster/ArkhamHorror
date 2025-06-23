module Arkham.Location.Cards.Lounge_RtTCU (lounge, Lounge(..)) where

import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype Lounge_RtTCU = Lounge LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

Lounge_RtTCU :: LocationCard Lounge_RtTCU
Lounge_RtTCU = location Lounge_RtTCU Cards.lounge_RtTCU 2 (PerPlayer 2)

-- Card code: 54043b
-- Class: Mythos
-- Type: Location
-- Traits: [Lodge]
-- Set: ReturnToTheCircleUndone
-- Encounter Set: ReturnToForTheGreaterGood
-- Revealed Symbol: Moon
-- Revealed Connections: ['Circle', 'Heart', 'Plus', 'Trefoil']
-- Victory: 0
-- Unrevealed Card Id: 54043
-- Unrevealed Symbol: Moon
-- Unrevealed Connections: ['Circle', 'Heart', 'Plus']

-- Revealed Abilities:
-- <b>Forced</b> - After the Lounge is revealed: Put the set-aside Vault and Library locations into play. [action] Investigators at the Lounge spend 1 [per_investigator] clues, as a group: Put the set-aside Hidden Passageway location into play.
-- Unrevealed Abilities:

-- TODO Card Text:


instance HasAbilities Lounge_RtTCU where
  getAbilities (Lounge attrs) = extendRevealed attrs []

instance RunMessage Lounge_RtTCU where
  runMessage msg l@(Lounge_RtTCU attrs) = runQueueT $ case msg of
    -- Example of using Projection helpers:
    -- shroudValue <- fieldJust LocationShroud attrs.id
    -- clueCount <- fieldMap LocationClues length attrs.id
    _ -> Lounge <$> liftRunMessage msg attrs
