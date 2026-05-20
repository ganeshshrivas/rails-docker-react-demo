import client from './client';

export const signup = (user) => client.post('/signup', { user });
export const login = (user) => client.post('/login', { user });
export const fetchMe = () => client.get('/me');
