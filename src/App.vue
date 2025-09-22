<script setup>
import { ref, onMounted, computed } from 'vue';

// Reactive variables to hold our data
const localModels = ref([]);
const newModelName = ref('');
const statusMessage = ref('');
const isLoading = ref(false);
const pullingModel = ref(''); // Track which specific model is being pulled

// A curated list of popular models available to download
const discoverableModels = ref([
  'llama3:8b',
  'gemma:7b',
  'phi3:latest',
  'mistral:latest',
  'codellama:7b',
  'llava:latest',
  'qwen:7b',
  'mixtral:latest'
]);

// Function to fetch the list of LOCALLY DOWNLOADED models
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

// Updated function to add a new model.
const addModel = async (modelToPull) => {
  if (!modelToPull) {
    statusMessage.value = 'Error: Please enter or select a model name.';
    return;
  }
  statusMessage.value = `Pulling model: ${modelToPull}... (This can take a while)`;
  isLoading.value = true;
  pullingModel.value = modelToPull; // Set the currently pulling model
  try {
    const response = await fetch('/modelmanager/api/models/pull', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: modelToPull }),
    });

    if (!response.ok) throw new Error(`Failed to pull model. Server responded with status ${response.status}`);
    
    // The response from Ollama is a stream, we just need to wait for it to finish
    await response.body.getReader().read();

    statusMessage.value = `Success! Model '${modelToPull}' has been pulled.`;
    newModelName.value = ''; // Clear the input field
    await fetchLocalModels(); // Refresh the list of local models
  } catch (error) {
    console.error(error);
    statusMessage.value = `Error: ${error.message}`;
  } finally {
    isLoading.value = false;
    pullingModel.value = ''; // Reset
  }
};

// Dynamically compute the class for the status message bar
const statusClass = computed(() => {
  if (!statusMessage.value) return '';
  const lowerCaseMessage = statusMessage.value.toLowerCase();
  if (lowerCaseMessage.startsWith('error')) return 'status-error';
  if (lowerCaseMessage.startsWith('success')) return 'status-success';
  return 'status-info';
});

// Fetch local models when the component is first loaded
onMounted(fetchLocalModels);
</script>

<template>
  <main class="container">
    <header>
      <h1>Ollama Model Manager</h1>
      <p>A simple interface to view and add models to your Ollama engine.</p>
    </header>

    <div class="main-content">
      <div class="control-panel">
        <section class="card">
          <h2>Add New Model</h2>
          <form @submit.prevent="addModel(newModelName)">
            <input
              v-model="newModelName"
              type="text"
              placeholder="Type a model name (e.g., 'gemma:2b')"
              :disabled="isLoading"
            />
            <button type="submit" :disabled="isLoading">
              <span v-if="isLoading && pullingModel === newModelName" class="spinner"></span>
              {{ isLoading && pullingModel === newModelName ? 'Pulling...' : 'Pull Model' }}
            </button>
          </form>

          <div class="discover-section">
            <h3 class="discover-title">Or choose from popular models</h3>
            <ul class="discover-list">
              <li v-for="model in discoverableModels" :key="model">
                <span>{{ model }}</span>
                <button @click="addModel(model)" :disabled="isLoading" class="pull-btn">
                   <span v-if="isLoading && pullingModel === model" class="spinner"></span>
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
            <h2>Locally Downloaded Models</h2>
            <button @click="fetchLocalModels" :disabled="isLoading" class="refresh-btn" title="Refresh list">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21.5 2v6h-6M2.5 22v-6h6"/><path d="M22 11.5A10 10 0 0 0 3.5 12.5"/><path d="M2 12.5a10 10 0 0 0 18.5-1"/></svg>
            </button>
          </div>
          
          <div v-if="statusMessage" class="status-message" :class="statusClass">
            <p>{{ statusMessage }}</p>
          </div>

          <div v-if="isLoading && localModels.length === 0" class="loading-placeholder">Loading models...</div>
          <ul v-else-if="localModels.length > 0" class="local-models-list">
            <li v-for="model in localModels" :key="model.digest">
              <div class="model-info">
                <span class="model-name">{{ model.name }}</span>
                <small class="model-details">Modified: {{ new Date(model.modified_at).toLocaleDateString() }}</small>
              </div>
              <span class="model-size">{{ (model.size / 1e9).toFixed(2) }} GB</span>
            </li>
          </ul>
          <p v-else class="no-models-message">No local models found. Pull a model to get started! ✨</p>
        </section>
      </div>
    </div>
  </main>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap');

:root {
  --primary-color: #4f46e5;
  --primary-hover: #4338ca;
  --background-color: #f8fafc;
  --card-background: #ffffff;
  --text-color: #1e293b;
  --subtle-text-color: #64748b;
  --border-color: #e2e8f0;
  --font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  --success-bg: #dcfce7;
  --success-text: #166534;
  --error-bg: #fee2e2;
  --error-text: #991b1b;
  --info-bg: #e0e7ff;
  --info-text: #3730a3;
}

body {
  font-family: var(--font-family);
  background-color: var(--background-color);
  color: var(--text-color);
  margin: 0;
  padding: 2rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

header {
  text-align: center;
  margin-bottom: 3rem;
}
h1 {
  color: var(--text-color);
  font-weight: 600;
}
header p {
  color: var(--subtle-text-color);
  font-size: 1.1rem;
}

.main-content {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 2rem;
}

.control-panel, .display-panel {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.card {
  background-color: var(--card-background);
  border-radius: 12px;
  border: 1px solid var(--border-color);
  padding: 1.5rem 2rem;
  box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.05), 0 2px 4px -2px rgb(0 0 0 / 0.05);
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
  margin-top: 0;
}

form { display: flex; flex-direction: column; gap: 0.75rem; }

input[type="text"] {
  font-size: 1rem;
  padding: 0.75rem 1rem;
  border-radius: 8px;
  border: 1px solid var(--border-color);
  width: 100%;
  box-sizing: border-box;
  transition: border-color 0.2s, box-shadow 0.2s;
}
input[type="text"]:focus {
  outline: none;
  border-color: var(--primary-color);
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.2);
}

button {
  font-size: 1rem;
  font-weight: 500;
  padding: 0.75rem;
  border-radius: 8px;
  border: none;
  background-color: var(--primary-color);
  color: white;
  cursor: pointer;
  transition: background-color 0.2s;
  display: inline-flex;
  justify-content: center;
  align-items: center;
  gap: 0.5rem;
}
button:disabled {
  background-color: #cbd5e1;
  cursor: not-allowed;
}
button:not(:disabled):hover {
  background-color: var(--primary-hover);
}

.discover-section { margin-top: 2rem; }
.discover-title {
  font-size: 0.9rem;
  font-weight: 500;
  color: var(--subtle-text-color);
  border-bottom: 1px solid var(--border-color);
  padding-bottom: 0.75rem;
  margin-bottom: 0.5rem;
}

.discover-list, .local-models-list {
  list-style-type: none;
  padding: 0;
  margin: 0;
}
.discover-list li, .local-models-list li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0.5rem;
  border-bottom: 1px solid var(--border-color);
}
.discover-list li:last-child, .local-models-list li:last-child {
  border-bottom: none;
}

.pull-btn {
  width: 80px;
  padding: 0.5rem 1rem;
  font-size: 0.9rem;
}

.refresh-btn {
  background: none;
  color: var(--subtle-text-color);
  padding: 0.5rem;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  transition: background-color 0.2s, color 0.2s;
}
.refresh-btn:hover:not(:disabled) {
  background-color: #f1f5f9;
  color: var(--text-color);
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

.local-models-list li {
  gap: 1rem;
}
.model-info {
  display: flex;
  flex-direction: column;
  flex-grow: 1;
}
.model-name {
  font-weight: 500;
}
.model-details {
  font-size: 0.85rem;
  color: var(--subtle-text-color);
}
.model-size {
  font-weight: 500;
  font-size: 0.9rem;
  background-color: #f1f5f9;
  padding: 0.25rem 0.75rem;
  border-radius: 1rem;
}
.no-models-message, .loading-placeholder {
  text-align: center;
  color: var(--subtle-text-color);
  padding: 2rem 0;
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  border-top-color: #fff;
  animation: spin 1s ease-in-out infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}

@media (max-width: 900px) {
  .main-content {
    grid-template-columns: 1fr;
  }
}
</style>