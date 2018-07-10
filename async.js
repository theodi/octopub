/*jshint esversion: 6 */
const fetch = require('node-fetch');

function fetchCatAvatars(userId) {
	return fetch('https://catappapi.herokuapp.com/users/' + userId)
		.then(response => response.json())
		.then(user => {
			const promises = user.cats.map(catId =>
				fetch('https://catappapi.herokuapp.com/cats/' + catId)
					.then(response => response.json())
					.then(catData => catData.imageUrl)
			)
			return Promise.all(promises);
		})
}

const catResults = fetchCatAvatars(123);
catResults //?

async function fetchAvatar(userId) {
	const response = await fetch('https://catappapi.herokuapp.com/users/' + userId); //?
	const data = await response.json();
	return data.imageUrl

const result = fetchAvatar(123);
result; //?
