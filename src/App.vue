<script setup>
import { computed, ref, watch } from 'vue'

const storageKey = 'todo-list-items'
const categories = ['收件箱', '工作', '生活', '学习']
const filter = ref('全部')
const query = ref('')
const draft = ref('')
const selectedCategory = ref('收件箱')
const todos = ref(loadTodos())

function loadTodos() {
  try {
    const saved = JSON.parse(localStorage.getItem(storageKey) || '[]')
    return Array.isArray(saved) ? saved : []
  } catch {
    return []
  }
}

function persist() {
  localStorage.setItem(storageKey, JSON.stringify(todos.value))
}

function addTodo() {
  const title = draft.value.trim()
  if (!title) return
  todos.value.unshift({
    id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
    title,
    category: selectedCategory.value,
    done: false,
    createdAt: new Date().toISOString(),
  })
  draft.value = ''
}

function toggleTodo(todo) {
  todo.done = !todo.done
}

function removeTodo(todo) {
  todos.value = todos.value.filter((item) => item.id !== todo.id)
}

const visibleTodos = computed(() => {
  const normalizedQuery = query.value.trim().toLowerCase()
  return todos.value.filter((todo) => {
    const matchesFilter = filter.value === '全部' || todo.category === filter.value
    const matchesQuery = !normalizedQuery || todo.title.toLowerCase().includes(normalizedQuery)
    return matchesFilter && matchesQuery
  })
})

const pendingCount = computed(() => todos.value.filter((todo) => !todo.done).length)

watch(todos, persist, { deep: true })
</script>

<template>
  <main class="app-shell">
    <aside class="sidebar">
      <div class="brand">
        <span class="brand-mark">✓</span>
        <span>Todo List</span>
      </div>
      <button
        v-for="item in ['全部', ...categories]"
        :key="item"
        class="nav-item"
        :class="{ active: filter === item }"
        @click="filter = item"
      >
        <span>{{ item === '全部' ? '◷' : '○' }}</span>
        {{ item }}
        <strong v-if="item === '全部'">{{ pendingCount }}</strong>
      </button>
      <div class="sidebar-footer">本地保存 · 无需联网</div>
    </aside>

    <section class="content">
      <header class="toolbar">
        <div>
          <p class="eyebrow">今日清单</p>
          <h1>{{ filter }}</h1>
        </div>
        <input v-model="query" class="search" placeholder="搜索任务..." aria-label="搜索任务" />
      </header>

      <form class="composer" @submit.prevent="addTodo">
        <input v-model="draft" autofocus placeholder="添加一个新任务..." aria-label="新任务标题" />
        <select v-model="selectedCategory" aria-label="任务分类">
          <option v-for="category in categories" :key="category">{{ category }}</option>
        </select>
        <button type="submit">添加</button>
      </form>

      <div v-if="visibleTodos.length" class="todo-list">
        <article v-for="todo in visibleTodos" :key="todo.id" class="todo-card" :class="{ done: todo.done }">
          <button class="check" :aria-label="todo.done ? '标记未完成' : '标记完成'" @click="toggleTodo(todo)">
            {{ todo.done ? '✓' : '' }}
          </button>
          <div class="todo-copy">
            <span class="todo-title">{{ todo.title }}</span>
            <span class="todo-meta">{{ todo.category }}</span>
          </div>
          <button class="delete" aria-label="删除任务" @click="removeTodo(todo)">删除</button>
        </article>
      </div>
      <div v-else class="empty">
        <div class="empty-icon">✓</div>
        <h2>还没有任务</h2>
        <p>在上方输入任务，开始安排今天的工作。</p>
      </div>
    </section>
  </main>
</template>
