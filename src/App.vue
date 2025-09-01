<script setup>
import { ref, onMounted } from 'vue';

// Reactive variables to hold our data
const localModels = ref([]);
const newModelName = ref('');
const statusMessage = ref('');
const isLoading = ref(false);

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
    // UPDATED: Calls the proxied endpoint
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

// Updated function to add a new model. It now accepts a model name as an argument.
const addModel = async (modelToPull) => {
  if (!modelToPull) {
    statusMessage.value = 'Please enter or select a model name.';
    return;
  }
  statusMessage.value = `Pulling model: ${modelToPull}... (This can take a while)`;
  isLoading.value = true;
  try {
    // UPDATED: Calls the proxied endpoint
    const response = await fetch('/modelmanager/api/models/pull', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: modelToPull }),
    });

    if (!response.ok) throw new Error(`Failed to pull model. Server responded with status ${response.status}`);

    // The response from Ollama is a stream of JSON objects. We'll just read it to completion.
    await response.body.getReader().read();

    statusMessage.value = `Successfully pulled ${modelToPull}!`;
    newModelName.value = ''; // Clear the input field
    await fetchLocalModels(); // Refresh the list of local models
  } catch (error) {
    console.error(error);
    statusMessage.value = `Error: ${error.message}`;
  } finally {
    isLoading.value = false;
  }
};

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
          <h2>Discover Models</h2>
          <ul class="discover-list">
            <li v-for="model in discoverableModels" :key="model">
              <span>{{ model }}</span>
              <button @click="addModel(model)" :disabled="isLoading">Pull</button>
            </li>
          </ul>
        </section>

        <section class="card">
          <h2>Add Manually</h2>
          <form @submit.prevent="addModel(newModelName)">
            <input
              v-model="newModelName"
              type="text"
              placeholder="Or type a model name here"
              :disabled="isLoading"
            />
            <button type="submit" :disabled="isLoading">
              {{ isLoading ? 'Working...' : 'Pull Model' }}
            </button>
          </form>
        </section>
      </div>

      <div class="display-panel">
         <div v-if="statusMessage" class="status-message">
          <p>{{ statusMessage }}</p>
        </div>
        <section class="card">
          <h2>
            Locally Downloaded Models
            <button @click="fetchLocalModels" :disabled="isLoading" class="refresh-btn">🔄</button>
          </h2>
          <div v-if="isLoading && localModels.length === 0">Loading...</div>
          <ul v-else-if="localModels.length > 0" class="local-models-list">
            <li v-for="model in localModels" :key="model.digest">
              <span>{{ model.name }}</span>
              <small>Size: {{ (model.size / 1e9).toFixed(2) }} GB</small>
            </li>
          </ul>
          <p v-else>No local models found. Pull a model to get started!</p>
        </section>
      </div>
    </div>
  </main>
</template>

<style>
:root {
  --primary-color: #007bff;
  --background-color: #f4f7f6;
  --card-background: #ffffff;
  --text-color: #333;
  --border-color: #e0e0e0;
  --font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
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

header { text-align: center; margin-bottom: 2rem; }
h1 { color: var(--primary-color); }

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
  border-radius: 8px;
  border: 1px solid var(--border-color);
  padding: 1.5rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

input, button {
  font-size: 1rem;
  padding: 0.75rem;
  border-radius: 4px;
  border: 1px solid var(--border-color);
  width: 100%;
  box-sizing: border-box;
}

button {
  background-color: var(--primary-color);
  color: white;
  border: none;
  cursor: pointer;
  transition: background-color 0.2s;
}

button:disabled { background-color: #cccccc; cursor: not-allowed; }
button:not(:disabled):hover { background-color: #0056b3; }

.discover-list, .local-models-list { list-style-type: none; padding: 0; }

.discover-list li, .local-models-list li {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--border-color);
}
.discover-list li:last-child, .local-models-list li:last-child { border-bottom: none; }

.discover-list button { width: auto; padding: 0.5rem 1rem; }

.refresh-btn { background: none; border: none; font-size: 1.2rem; cursor: pointer; padding: 0.2rem; margin-left: 0.5rem; width: auto; }

.status-message { text-align: center; padding: 1rem; background-color: #e7f3ff; border: 1px solid #b3d7ff; border-radius: 4px; }

@media (max-width: 900px) {
  .main-content { grid-template-columns: 1fr; }
}
</style>