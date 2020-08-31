{-# LANGUAGE UndecidableInstances #-}
module Arkham.Types.Event.Cards.Barricade2 where

import Arkham.Json
import Arkham.Types.Classes
import Arkham.Types.Event.Attrs
import Arkham.Types.Event.Runner
import Arkham.Types.EventId
import Arkham.Types.InvestigatorId
import Arkham.Types.Message
import Arkham.Types.Modifier
import Arkham.Types.Source
import Arkham.Types.Target
import ClassyPrelude
import Lens.Micro
import Safe (fromJustNote)

newtype Barricade2 = Barricade2 Attrs
  deriving newtype (Show, ToJSON, FromJSON)

barricade :: InvestigatorId -> EventId -> Barricade2
barricade iid uuid = Barricade2 $ baseAttrs iid uuid "01038"

instance HasActions env investigator Barricade2 where
  getActions i window (Barricade2 attrs) = getActions i window attrs

instance (EventRunner env) => RunMessage env Barricade2 where
  runMessage msg e@(Barricade2 attrs@Attrs {..}) = case msg of
    InvestigatorPlayEvent iid eid | eid == eventId -> do
      lid <- asks (getId iid)
      e <$ unshiftMessage (AttachEventToLocation eid lid)
    MoveFrom _ lid | Just lid == eventAttachedLocation ->
      e <$ unshiftMessage (Discard (EventTarget eventId))
    AttachEventToLocation eid lid | eid == eventId -> do
      unshiftMessage
        (AddModifier
          (LocationTarget lid)
          (CannotBeEnteredByNonElite (EventSource eid))
          (SpawnNonEliteAtConnectingInstead (EventSource eid))
        )
      pure . Barricade2 $ attrs & attachedLocation ?~ lid
    Discard (EventTarget eid) | eid == eventId -> do
      unshiftMessages
        [ RemoveAllModifiersOnTargetFrom
            (LocationTarget
            $ fromJustNote "had to have been attached" eventAttachedLocation
            )
            (EventSource eventId)
        ]
      Barricade2 <$> runMessage msg attrs
    _ -> Barricade2 <$> runMessage msg attrs
