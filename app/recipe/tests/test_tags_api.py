"""
Test for tags APIs
"""
from django.contrib.auth import get_user_model
from django.urls import reverse
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient
from core.models import (
    Tag,
    Recipe,
)
from recipe.serializers import TagSerializer
from decimal import Decimal


TAGS_URL = reverse('recipe:tag-list')


def detail_url(tag_id):
    """Create and return detail tag url"""
    return reverse('recipe:tag-detail', args=[tag_id])


def create_user(email='user@example.com', password='testpass123'):
    """Create and return user"""
    return get_user_model().objects.create_user(email, password)


class PublicTagsAPITests(TestCase):
    """Test unauthentiacted API requests"""

    def setUp(self):
        self.client = APIClient()

    def test_auth_required(self):
        """Test auth is required for retrieving tags"""
        res = self.client.get(TAGS_URL)

        self.assertEqual(res.status_code, status.HTTP_401_UNAUTHORIZED)


class PrivateTagsAPITests(TestCase):
    """Test authenticated API requests"""

    def setUp(self):
        self.client = APIClient()
        self.user = create_user()
        self.client.force_authenticate(self.user)

    def test_retrieve_tags(self):
        """Test retrieving a list of tags"""
        Tag.objects.create(user=self.user, name='Test tag 1')
        Tag.objects.create(user=self.user, name='Test tag 2')

        res = self.client.get(TAGS_URL)

        tags = Tag.objects.all().order_by('-name')
        serializer = TagSerializer(tags, many=True)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(res.data, serializer.data)

    def test_tags_limited_to_user(self):
        """test list of tags is limited to authenticated user"""
        user2 = create_user(email='user2@example.com', password='testpass123')
        Tag.objects.create(user=user2, name='Tag user 2')
        tag = Tag.objects.create(user=self.user, name='Tag authenticated user')

        res = self.client.get(TAGS_URL)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertEqual(len(res.data), 1)
        self.assertEqual(res.data[0]['name'], tag.name)
        self.assertEqual(res.data[0]['id'], tag.id)

    def test_update_tag(self):
        """Test updating a tag"""
        tag = Tag.objects.create(user=self.user, name='after dinner')

        payload = {
            'name': 'after dinner updated'
        }
        url = detail_url(tag.id)
        res = self.client.patch(url, payload)

        self.assertEqual(res.status_code, status.HTTP_200_OK)
        tag.refresh_from_db()
        self.assertEqual(tag.name, payload['name'])

    def test_delete_tag(self):
        """Test deleting a tag"""
        tag = Tag.objects.create(user=self.user, name='after dinner')

        url = detail_url(tag.id)

        res = self.client.delete(url)

        self.assertEqual(res.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Tag.objects.filter(user=self.user).exists())

    def test_filter_tags_assigned_to_recipes(self):
        """Listing tags to those assigned to recipes"""
        tag1 = Tag.objects.create(user=self.user, name='Apple')
        tag2 = Tag.objects.create(user=self.user, name='Turkey')
        recipe = Recipe.objects.create(
            user=self.user, title='recipe1', time_minutes=5, price=Decimal('5.0'))
        recipe.tags.add(tag1)

        res = self.client.get(TAGS_URL, {'assigned_only': 1})

        s1 = TagSerializer(tag1)
        s2 = TagSerializer(tag2)
        self.assertIn(s1.data, res.data)
        self.assertNotIn(s2.data, res.data)

    def test_filterred_tags_unique(self):
        """Test filtered tags return a unique list"""
        tag = Tag.objects.create(user=self.user, name='Apple')
        Tag.objects.create(user=self.user, name='Pear')
        recipe1 = Recipe.objects.create(
            user=self.user, title='recipe1', time_minutes=5, price=Decimal('5.0'))
        recipe2 = Recipe.objects.create(
            user=self.user, title='recipe2', time_minutes=15, price=Decimal('15.0'))

        recipe1.tags.add(tag)
        recipe2.tags.add(tag)

        res = self.client.get(TAGS_URL, {'assigned_only': 1})

        self.assertEqual(len(res.data), 1)
