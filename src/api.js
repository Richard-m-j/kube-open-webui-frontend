import axios from 'axios';

const api = axios.create({
  baseURL: '/modelmanager/api', // all requests will be prefixed with this
});

export default api;
