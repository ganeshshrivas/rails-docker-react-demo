import client from './client';

export const fetchPosts = () => client.get('/posts');
export const fetchPost = (id) => client.get(`/posts/${id}`);
export const createPost = (post) => client.post('/posts', { post });
export const updatePost = (id, post) => client.put(`/posts/${id}`, { post });
export const deletePost = (id) => client.delete(`/posts/${id}`);
