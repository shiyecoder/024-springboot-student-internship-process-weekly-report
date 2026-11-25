<template>
  <div ref="el" class="chart" :style="{ height: height + 'px' }"></div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref, watch, nextTick } from 'vue'
import * as echarts from 'echarts'

/** 图表容器：统一主题色与自适应，页面只传 option */
const props = defineProps({
  option: { type: Object, required: true },
  height: { type: Number, default: 240 }
})
const el = ref(null)
let chart = null

const PALETTE = ['#234E3B', '#3A7D5A', '#315F4C', '#6B8F7C', '#9DB8A8', '#C9DBD0', '#B7791F']

function render() {
  if (!el.value) return
  if (!chart) chart = echarts.init(el.value)
  chart.setOption({ color: PALETTE, ...props.option }, true)
}

const resize = () => chart && chart.resize()

onMounted(async () => {
  await nextTick()
  render()
  window.addEventListener('resize', resize)
})

watch(() => props.option, render, { deep: true })

onBeforeUnmount(() => {
  window.removeEventListener('resize', resize)
  chart && chart.dispose()
  chart = null
})
</script>

<style scoped>
.chart { width: 100%; }
</style>
