<script lang="ts" setup>
import Draggable from '@/components/Draggable.vue';
import { computed } from 'vue';
import { useDebug } from '@/arkham/debug';
import { TokenType } from '@/arkham/types/Token';
import { imgsrc } from '@/arkham/helpers';
import type { Game } from '@/arkham/types/Game';
import PoolItem from '@/arkham/components/PoolItem.vue';
import * as Arkham from '@/arkham/types/Enemy'

const props = defineProps<{
  game: Game
  enemy: Arkham.Enemy
  playerId: string
}>()

const emit = defineEmits<{ close: [] }>()

const isTrueForm = computed(() => {
  const { cardCode } = props.enemy
  return cardCode === 'cxnyarlathotep'
})

function mapMaybe<T, U>(arr: T[], fn: (item: T) => U | null | undefined): U[] {
  return arr.reduce((acc: U[], item: T) => {
    const result = fn(item);
    if (result !== null && result !== undefined) {
      acc.push(result);
    }
    return acc;
  }, []);
}

const addedKeywords = computed(() => {
  const {modifiers} = props.enemy
  return mapMaybe(modifiers, modifier => modifier.type.tag === "AddKeyword" ? modifier.type.contents : null).join(". ")
})

const gainedVictory = computed(() => {
  const {modifiers} = props.enemy

  return modifiers.reduce((acc, modifier) =>
    acc + (modifier.type.tag === "GainVictory" ? modifier.type.contents : 0)
  , 0)
})

const health = computed(() => {
  return props.enemy.health?.tag == "Static" ? props.enemy.health.contents : null
})


const investigatorId = computed(() => Object.values(props.game.investigators).find(i => i.playerId === props.playerId)?.id)
const id = computed(() => props.enemy.id)

const cardCode = computed(() => props.enemy.cardCode)
const image = computed(() => {
  return imgsrc(`cards/${cardCode.value.replace('c', '')}.jpg`)
})

const debug = useDebug()
const damage = computed(() => props.enemy.tokens[TokenType.Damage])

const hasPool = computed(() => {
  const { sanity, health, } = props.enemy;
  return cardCode.value == 'c07189' || sanity || health
})
</script>

<template>
  <Draggable>
    <template #handle><h2>Debug Enemy</h2></template>
    <div class="enemy--outer">
      <div class="enemy" :data-index="enemy.cardId">
        <div class="card-frame">
          <div class="card-wrapper">
            <img v-if="isTrueForm" :src="image"
              class="card enemy"
              :data-id="id"
              :data-fight="enemy.fight"
              :data-evade="enemy.evade"
              :data-health="health"
              :data-damage="enemy.healthDamage"
              :data-horror="enemy.sanityDamage"
              :data-victory="gainedVictory"
              :data-keywords="addedKeywords"
            />
            <img v-else
              :src="image"
              class="card enemy"
              :data-id="id"
            />
          </div>
          <div v-if="hasPool" class="pool">
            <PoolItem
              v-if="cardCode == 'c07189' || (enemy.health !== null || (damage || 0) > 0)"
              type="health"
              :amount="damage || 0"
            />
          </div>
        </div>
      </div>
      <div class="buttons">
        <button @click="debug.send(game.id, {tag: 'DefeatEnemy', contents: [id, investigatorId, {tag: 'InvestigatorSource', contents:investigatorId}]})">Defeat</button>
        <button @click="debug.send(game.id, {tag: 'EnemyEvaded', contents: [investigatorId, id]})">Evade</button>
        <button @click="debug.send(game.id, {tag: 'EnemyDamage', contents: [id, {damageAssignmentSource: {tag: 'InvestigatorSource', contents:investigatorId}, damageAssignmentAmount: 1, damageAssignmentDirect: true, damageAssignmentDelayed: false, damageAssignmentDamageEffect: 'NonAttackDamageEffect'}]})">Add Damage</button>
        <button @click="emit('close')">Close</button>
      </div>
    </div>
  </Draggable>
</template>

<style lang="scss" scoped>
.enemy {
  display: flex;
  flex-direction: column;
}

.buttons {
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  flex: 1;
  gap: 5px;
}

.enemy--outer {
  padding: 10px;
  display: flex;
  flex-direction: row;
  align-items: center;
  gap: 10px;
}

.pool {
  position: absolute;
  top: 50%;
  align-items: center;
  width: 100%;
  display: flex;
  flex-wrap: wrap;
  pointer-events: none;
}

.button{
  margin-top: 2px;
  border: 0;
  color: #fff;
  border-radius: 4px;
  border: 1px solid #ff00ff;
}

.card-frame {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
