{-# LANGUAGE TemplateHaskell #-}

module Arkham.Card.CardType where

import Arkham.Prelude
import Data.Aeson.TH

data CardType
  = AssetType
  | EventType
  | SkillType
  | PlayerTreacheryType
  | PlayerEnemyType
  | TreacheryType
  | EnemyType
  | LocationType
  | EncounterAssetType
  | EncounterEventType
  | KeyType
  | ActType
  | AgendaType
  | StoryType
  | InvestigatorType
  | ScenarioType
  deriving stock (Eq, Show, Ord, Data)

data CardSubType = Weakness | BasicWeakness
  deriving stock (Eq, Show, Ord, Data)

encounterCardTypes :: [CardType]
encounterCardTypes =
  [ TreacheryType
  , EnemyType
  , LocationType
  , EncounterAssetType
  , EncounterEventType
  , StoryType
  , ActType
  , AgendaType
  , KeyType
  ]

playerCardTypes :: [CardType]
playerCardTypes =
  [AssetType, EventType, SkillType, PlayerTreacheryType, PlayerEnemyType]

$(deriveJSON defaultOptions ''CardSubType)
$(deriveJSON defaultOptions ''CardType)
