<script setup>
import { ref, onMounted, computed } from 'vue';

// --- THEME SWITCHER LOGIC ---
const theme = ref('light');

const setTheme = (newTheme) => {
  theme.value = newTheme;
  localStorage.setItem('theme', newTheme);
  // This applies the class to the root <html> element
  document.documentElement.className = newTheme;
};

const toggleTheme = () => {
  setTheme(theme.value === 'dark' ? 'light' : 'dark');
};

// --- EXISTING APP LOGIC ---
const localModels = ref([]);
const newModelName = ref('');
const statusMessage = ref('');
const isLoading = ref(false);
const pullingModel = ref('');

const discoverableModels = ref([
  'llama3:8b', 'gemma:7b', 'phi3:latest', 'mistral:latest',
  'codellama:7b', 'llava:latest', 'qwen:7b', 'mixtral:latest'
]);

const localModelNames = computed(() => {
  return new Set(localModels.value.map(model => model.name));
});

const fetchLocalModels = async () => {
  statusMessage.value = 'Fetching local models...';
  isLoading.value = true;
  try {
    const response = await fetch('/modelmanager/api/models');
    if (!response.ok) throw new Error('Failed to fetch local models');
    const data = await response.json();
    localModels.value = data.models || [];
    statusMessage.value = '';
  } catch (error) {
    console.error(error);
    statusMessage.value = 'Error: Could not connect to the backend.';
  } finally {
    isLoading.value = false;
  }
};

const addModel = async (modelToPull) => {
  if (!modelToPull) {
    statusMessage.value = 'Error: Please enter or select a model name.';
    return;
  }
  statusMessage.value = `Pulling model: ${modelToPull}... (This can take a while)`;
  isLoading.value = true;
  pullingModel.value = modelToPull;
  try {
    const response = await fetch('/modelmanager/api/models/pull', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: modelToPull }),
    });

    if (!response.ok) throw new Error(`Failed to pull model. Server responded with status ${response.status}`);
    
    await response.body.getReader().read();

    statusMessage.value = `Success! Model '${modelToPull}' has been pulled.`;
    newModelName.value = '';
    await fetchLocalModels();
  } catch (error) {
    console.error(error);
    statusMessage.value = `Error: ${error.message}`;
  } finally {
    isLoading.value = false;
    pullingModel.value = '';
  }
};

const statusClass = computed(() => {
  if (!statusMessage.value) return '';
  const lowerCaseMessage = statusMessage.value.toLowerCase();
  if (lowerCaseMessage.startsWith('error')) return 'status-error';
  if (lowerCaseMessage.startsWith('success')) return 'status-success';
  return 'status-info';
});

onMounted(() => {
  // Initialize theme on component mount
  const savedTheme = localStorage.getItem('theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  if (savedTheme) {
    setTheme(savedTheme);
  } else {
    setTheme(prefersDark ? 'dark' : 'light');
  }

  // Fetch models
  fetchLocalModels();
});
</script>

<template>
  <main class="container">
    <header class="app-header">
      <div class="header-content">
        <h1>Ollama Model Manager</h1>
        <p>A simple interface to view and add models to your Ollama engine.</p>
      </div>
      <button @click="toggleTheme" class="theme-toggle-btn" title="Toggle theme">
        <svg v-if="theme === 'light'" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>
        <svg v-else xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>
      </button>
    </header>

    <div class="main-content">
      <div class="control-panel">
        <section class="card">
          <h2>Add New Model</h2>
          <form @submit.prevent="addModel(newModelName)">
            <input
              v-model="newModelName"
              type="text"
              placeholder="e.g., 'gemma:2b'"
              :disabled="isLoading"
            />
            <button type="submit" :disabled="isLoading || !newModelName">
              <span v-if="isLoading && pullingModel === newModelName" class="spinner"></span>
              <span v-else>Pull Model</span>
            </button>
          </form>

          <div class="discover-section">
            <h3 class="discover-title">Or choose from popular models</h3>
            <ul class="styled-list">
              <li v-for="model in discoverableModels" :key="model">
                <code>{{ model }}</code>
                <button
                  @click="addModel(model)"
                  :disabled="isLoading || localModelNames.has(model)"
                  class="pull-btn"
                >
                  <span v-if="isLoading && pullingModel === model" class="spinner"></span>
                  <span v-else-if="localModelNames.has(model)">✅ Installed</span>
                  <span v-else>Pull</span>
                </button>
              </li>
            </ul>
          </div>
        </section>
      </div>

      <div class="display-panel">
        <section class="card">
          <div class="card-header">
            <h2>Local Models</h2>
            <button @click="fetchLocalModels" :disabled="isLoading" class="refresh-btn" title="Refresh list">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M2.5 22v-6h6"/><path d="M22 11.5A10 10 0 0 0 3.5 12.5"/><path d="M2 12.5a10 10 0 0 0 18.5-1"/></svg>
            </button>
          </div>
          
          <div v-if="statusMessage" class="status-message" :class="statusClass">
            <p>{{ statusMessage }}</p>
          </div>

          <div v-if="isLoading && !localModels.length" class="placeholder-message">
            <div class="spinner"></div>
            <span>Loading models...</span>
          </div>
          <ul v-else-if="localModels.length > 0" class="styled-list local-models-list">
            <li v-for="model in localModels" :key="model.digest">
              <div class="model-info">
                <span class="model-name">{{ model.name }}</span>
                <small class="model-details">
                  Modified: {{ new Date(model.modified_at).toLocaleDateString() }}
                </small>
              </div>
              <span class="model-size">{{ (model.size / 1e9).toFixed(2) }} GB</span>
            </li>
          </ul>
          <p v-else class="placeholder-message">No local models found. Pull a model to get started! ✨</p>
        </section>
      </div>
    </div>
  </main>
</template>

<style>
/* 1. Global Styles & Theming */
:root {
  --font-sans: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  
  /* Light Theme Variables */
  --bg-primary: #f9fafb;
  --bg-secondary: #ffffff;
  --text-primary: #111827;
  --text-secondary: #6b7280;
  --border-color: #e5e7eb;
  --accent-primary: #4f46e5;
  --accent-primary-hover: #4338ca;
  --accent-text: #ffffff;
  --btn-disabled-bg: #e5e7eb;
  --btn-disabled-text: #9ca3af;

  --success-bg: #dcfce7; --success-text: #166534;
  --error-bg: #fee2e2;   --error-text: #991b1b;
  --info-bg: #e0e7ff;    --info-text: #3730a3;
}

/* Dark Theme Variables applied via a class on the <html> element */
html.dark {
  --bg-primary: #111827;
  --bg-secondary: #1f2937;
  --text-primary: #f9fafb;
  --text-secondary: #9ca3af;
  --border-color: #374151;
  --accent-primary: #6366f1;
  --accent-primary-hover: #818cf8;
  --btn-disabled-bg: #374151;
  --btn-disabled-text: #6b7280;
  
  --success-bg: #14532d; --success-text: #dcfce7;
  --error-bg: #991b1b;   --error-text: #fee2e2;
  --info-bg: #3730a3;    --info-text: #e0e7ff;
}

* {
  box-sizing: border-box;
}

body {
  font-family: var(--font-sans);
  background-color: var(--bg-primary);
  color: var(--text-primary);
  margin: 0;
  padding: 2rem;
  transition: background-color 0.3s ease, color 0.3s ease;
}

/* 2. Layout */
.container {
  max-width: 1200px;
  margin: 0 auto;
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  text-align: center;
  margin-bottom: 3rem;
}
.header-content { flex-grow: 1; }
.app-header h1 {
  font-size: 2.25rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}
.app-header p {
  color: var(--text-secondary);
  font-size: 1.125rem;
  margin-top: 0;
}

.main-content {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 2rem;
}

@media (max-width: 900px) {
  .main-content { grid-template-columns: 1fr; }
  .app-header { flex-direction: column; align-items: center; }
  .theme-toggle-btn { position: absolute; top: 1.5rem; right: 1.5rem; }
}

/* 3. Card & Panel Styles */
.card {
  background-color: var(--bg-secondary);
  border-radius: 12px;
  border: 1px solid var(--border-color);
  padding: 1.5rem 2rem;
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.03), 0 2px 4px -2px rgba(0,0,0,0.03);
  transition: background-color 0.3s ease, border-color 0.3s ease;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

h2 {
  font-size: 1.25rem;
  font-weight: 600;
  margin: 0;
}

/* 4. Form & Input Elements */
form { display: flex; flex-direction: column; gap: 0.75rem; }

input[type="text"] {
  font-family: var(--font-sans);
  font-size: 1rem;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  border: 1px solid var(--border-color);
  background-color: var(--bg-primary);
  color: var(--text-primary);
  width: 100%;
  transition: border-color 0.2s, box-shadow 0.2s;
}
input[type="text"]:focus {
  outline: none;
  border-color: var(--accent-primary);
  box-shadow: 0 0 0 3px color-mix(in srgb, var(--accent-primary) 20%, transparent);
}

button {
  font-family: var(--font-sans);
  font-size: 1rem;
  font-weight: 500;
  padding: 0.75rem;
  border-radius: 8px;
  border: none;
  background-color: var(--accent-primary);
  color: var(--accent-text);
  cursor: pointer;
  transition: background-color 0.2s;
  display: inline-flex;
  justify-content: center;
  align-items: center;
  gap: 0.5rem;
}
button:disabled {
  background-color: var(--btn-disabled-bg);
  color: var(--btn-disabled-text);
  cursor: not-allowed;
}
button:not(:disabled):hover {
  background-color: var(--accent-primary-hover);
}

/* 5. Component-Specific Styles */
.theme-toggle-btn {
  background: none;
  color: var(--text-secondary);
  padding: 0.5rem;
  border-radius: 50%;
  width: 44px;
  height: 44px;
}
.theme-toggle-btn:hover {
  background-color: color-mix(in srgb, var(--border-color) 50%, transparent);
  color: var(--text-primary);
}

.discover-section { margin-top: 2rem; }
.discover-title {
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--text-secondary);
  border-bottom: 1px solid var(--border-color);
  padding-bottom: 0.75rem;
  margin: 0 0 0.5rem 0;
}

.styled-list {
  list-style-type: none;
  padding: 0;
  margin: 0;
}
.styled-list li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0.5rem;
  border-bottom: 1px solid var(--border-color);
}
.styled-list li:last-child { border-bottom: none; }
.styled-list li code {
  font-family: monospace;
  background-color: var(--bg-primary);
  padding: 0.25rem 0.5rem;
  border-radius: 6px;
  font-size: 0.9rem;
}

.pull-btn {
  width: 100px;
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
}

.refresh-btn {
  background: none;
  color: var(--text-secondary);
  padding: 0.5rem;
  border-radius: 50%;
  width: 40px;
  height: 40px;
}
.refresh-btn:hover:not(:disabled) {
  background-color: color-mix(in srgb, var(--border-color) 50%, transparent);
  color: var(--text-primary);
}

.status-message {
  text-align: center;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1rem;
}
.status-message p { margin: 0; font-weight: 500; }
.status-info { background-color: var(--info-bg); color: var(--info-text); }
.status-success { background-color: var(--success-bg); color: var(--success-text); }
.status-error { background-color: var(--error-bg); color: var(--error-text); }

.local-models-list li { gap: 1rem; }
.model-info { display: flex; flex-direction: column; flex-grow: 1; }
.model-name { font-weight: 500; }
.model-details { font-size: 0.85rem; color: var(--text-secondary); }
.model-size {
  font-weight: 500;
  font-size: 0.9rem;
  background-color: var(--bg-primary);
  color: var(--text-secondary);
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  border: 1px solid var(--border-color);
}

.placeholder-message {
  text-align: center;
  color: var(--text-secondary);
  padding: 3rem 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 1rem;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid currentColor;
  border-color: var(--accent-text) transparent var(--accent-text) transparent;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
.placeholder-message .spinner {
    border-color: var(--text-secondary) transparent var(--text-secondary) transparent;
}
@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>