
const baseUrl = window._env_.API_BASE_URL;

const categorySelect = document.getElementById('category-select');
const uploadBtn = document.getElementById('upload-btn');
const container = document.getElementById('photos-container');
const fileInput = document.getElementById('fileInput');


// Image preview
function previewImage(files) {
    if (files.length > 0) {
        Array.from(files).forEach(file => {
            const reader = new FileReader();

            reader.onload = function(e) {
                const photoItem = document.createElement('div');
                photoItem.classList.add('photo-item');

                const img = document.createElement('img');
                img.src = e.target.result;
                img.alt = 'Фото';

                const deleteBtn = document.createElement('button');
                deleteBtn.textContent = '✖';
                deleteBtn.classList.add('delete-btn');

                deleteBtn.addEventListener('click', () => {
                    photoItem.remove();
                });

                photoItem.appendChild(img);
                photoItem.appendChild(deleteBtn);
                container.appendChild(photoItem);
            };

            reader.readAsDataURL(file);
        });
    }
}

// Upload photos
async function uploadPhotos(category) {
    const files = fileInput.files;

    if (files.length === 0) {
        alert('Будь ласка, виберіть фото для завантаження.');
        return;
    }

    const formData = new FormData();

    for (const file of files) {
        formData.append('photos', file);
    }

    formData.append('categories', JSON.stringify(category));

    try {
        const response = await fetch(`${baseUrl}/photos/uploadPhoto`, {
            method: 'POST',
            body: formData,
            credentials: "include"
        });

        if (!response.ok) {
            throw new Error('Помилка при завантаженні фото');
        }

        console.log('Фото успішно завантажено!');
        fetchPhotos(category);

    } catch (error) {
        console.error('Помилка:', error);
        alert('Помилка при завантаженні фото');
    }
}

// Fetch photos
async function fetchPhotos(category) {
    try {
        const response = await fetch(`${baseUrl}/photos/getPhotos`, {
            method: 'POST',
            body: JSON.stringify({ category }),
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: "include"
        });

        if (!response.ok) {
            throw new Error('Помилка при завантаженні фото');
        }

        const photos = await response.json();

        container.innerHTML = '';

        photos.forEach(photo => {
            const photoItem = document.createElement('div');
            photoItem.classList.add('photo-item');

            const img = document.createElement('img');
            img.src = photo.url;
            img.alt = 'Фото';

            const deleteBtn = document.createElement('button');
            deleteBtn.textContent = '✖';
            deleteBtn.classList.add('delete-btn');

            deleteBtn.addEventListener('click', async () => {
                await deletePhoto(photo.url, photoItem, category);
            });

            photoItem.appendChild(img);
            photoItem.appendChild(deleteBtn);
            container.appendChild(photoItem);
        });

    } catch (error) {
        console.error('Помилка:', error);
    }
}

// Delete photo
async function deletePhoto(photoUrl, photoItem, category) {
    try {
        const response = await fetch(`${baseUrl}/photos/deletePhoto`, {
            method: 'DELETE',
            body: JSON.stringify({
                url: photoUrl,
                category: category
            }),
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: "include"
        });

        if (!response.ok) {
            throw new Error('Помилка при видаленні фото');
        }

        console.log('Фото успішно видалено.');
        photoItem.remove();

    } catch (error) {
        console.error('Помилка:', error);
        alert('Помилка при видаленні фото');
    }
}

// Category change
categorySelect.addEventListener('change', (event) => {
    localStorage.setItem('category', event.target.value);
    fetchPhotos([event.target.value]);
});

// Upload button
uploadBtn.addEventListener('click', () => {
    uploadPhotos([categorySelect.value]);
});

// File count
fileInput.addEventListener('change', function() {
    document.getElementById("file-count").textContent =
        `Вибрано файлів: ${this.files.length}`;
});

// Reset file input after upload click
uploadBtn.addEventListener('click', function() {
    setTimeout(() => {
        fileInput.value = "";
        document.getElementById("file-count").textContent =
            "Вибрано файлів: 0";
    }, 100);
});

// Load saved category
const savedCategory = localStorage.getItem('category');

if (savedCategory) {
    categorySelect.value = savedCategory;
}

// Initial photos load
if (categorySelect.value) {
    fetchPhotos([categorySelect.value]);
}
