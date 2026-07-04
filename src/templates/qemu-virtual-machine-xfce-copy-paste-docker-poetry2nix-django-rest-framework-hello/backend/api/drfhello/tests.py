from django.test import SimpleTestCase


class HelloWorldTest(SimpleTestCase):
    databases = ()

    def test_returns_200(self):
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)

    def test_contains_message(self):
        response = self.client.get("/")
        self.assertIn("Hello world!!", response.content.decode())
