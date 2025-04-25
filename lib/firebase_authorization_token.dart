import 'package:googleapis_auth/auth_io.dart';

class AccessTokenFirebase {
  static const String FirebaseMessagingScope =
      "https://www.googleapis.com/auth/firebase.messaging";

  Future<String> getAccessToken() async {
    final accountCredentials = ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "notification-86c27",
      "private_key_id": "12ff08181d2fed08db497c5e3757f569b50b7182",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQD5Qrxlpui4NRkp\nQjq4vx1ON6cbOBAW79EOBRol9eW2aG4h7ZOq2omERrz92i2Dz99A96RJh1G2Hs2u\n8dG10Ex2Dxt22Z6Euitbtcrcl4HDybpiXUVGZmzk4mDBbugcl+A6isd6ZXO1XVjp\nqfX//Bs/2Z24qt9oaLGVYPkKff5/fOv/g6W5vs8cibmDh2NkO/Ls1q2UHSKZZ5Xa\nzlgQbVoPZ7uFaJIoF/j8Lk9m22+5ji1kFSMuh7nfMRa1u6pvhN4zTIRAoP4k6YWS\nUgGTU+mCwAwcuqsVzw+GEW88T8erhe1ravRUhlo7r0Vp707bPrMP/tob9DJR5uFy\nlHWdyanrAgMBAAECggEANqjzTmlNJEQEmf8biHLkdsgOfZIMOTNqySPGSafEMX1y\nFT+Xf8J/oIGwpQxIqdyWTRVhMfyaJxFXMnN19ORSOBt0/tmXAO0gX/KcI0aYHrqo\nhDSG4frJC2I3LIPpI4gMlFnlh4oi1xU6z7bFKtb6lMRgaWQTLL60npjO1AWwHv1z\nqt7v86By+Ibu4X7yrTUF3qstbkcW62DyABd8JkBwC+v7PDve2MfPyNf70Jg7cf+0\nZoQoVoR+hKz5xmzJfK5ZW+Owh8VxNmmfMXh3c9jw0u0KU+w0ucv9YIglF9Lz7uKs\nK8RkfUE4GEYf+iwa2+J9SeH/SekgRnsxn0sMgLYzsQKBgQD9cvRQB+ehkBMEFylR\ndz4trUrHfMYi8tUzXyTh//MNesCT7x4ZDd7fPyLqXXlXCt95VMsMrOR8BLR7Zumo\nVfX7R5JgDLmGV1peXilKeq35Qac0kdGAmJ0otcxH6rUM7MPM0yKzI6XZZGz0++c2\nAatO06iWpIvugP+OgmVnpu57OwKBgQD7xP1ed2piEiJo/20OfnU25FfI9XD3bja6\n2lRfeSVDaNLPw9ZCZ6K7DO5iIblO7YYuNWrLlOfLX/7bP+IM520hR61YHFH47qZc\nlC+uddR/q1z0WNHojdZdwnuCAWaBiFZtwMm3F797CK+wzUtU8T45bul3pr83RhQK\nsFR3LmTBEQKBgFzmQ/MJ0rd/rdiz/KslwB7SBDT24VFyHP/FgilsvdRVCD2xSiD4\n2paN9+hb9twW2i8JC5xLyzxCJT2OTVsslwtSAq8+OsqpPjCU5yGrshVJIVa9lENE\nrWZ8rLI3r8FbD7IGOhPbnzD+BIoPw4IiPn6YSpVdHwV/Ny0vUqgZohR9AoGBAJh3\nixiSKJKLeNstE9YbLtC3J5JDUM4GqI4vebj3nGFeMYwwhKhiKmIsSpCS662omgGR\nx8LRwi2fTK9p2HMIE0Z8KbWaMOoXXBfkhZuZL77A/+HZiATVIGRXSoRIZNM8xVph\nzcZbU1ImyH7BVEV0csJFMI2NJW9LuQdgEUa7ibiBAoGBAMWi2cURw/q+4ty06dOW\nXICH6JiCMaTVY0UORy5eLyx3ckreu50JGHtnV4m0y4cgp36Imaiyl5D7fDarMqq2\n45zhX7zlX2h4o7Kn2w6UHW96vYpCpXTSTwJrxv2pEE4W2NCy04KfkmHYBZcNzQIh\nTfZ1x/9423dVwOOOg6zrBJJ+\n-----END PRIVATE KEY-----\n",
      "client_email":
          "firebase-adminsdk-v4ov6@notification-86c27.iam.gserviceaccount.com",
      "client_id": "100114655584593235235",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-v4ov6%40notification-86c27.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    });

    final scopes = [FirebaseMessagingScope];

    final client = await clientViaServiceAccount(accountCredentials, scopes);

    return client.credentials.accessToken.data;
  }
}
