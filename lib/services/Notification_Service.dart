import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;

class NotificationService {
  static Future<String> getAccessToken() async {
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": "ekspedisisinarjaya",
      "private_key_id": "49a295daedd26ceced6b1da05679e8540b74750b",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkqhkiG9w0BAQEFAASCBKkwggSlAgEAAoIBAQC7PT/VEdWv03i7\ndQcVKL6MBJZxBTxzASTNbaNz7NIQqU3y8CrJAaCb7Ha7K/7iPeC9q0rdaSXU8KKG\nm4+5mAdKroIOAen/mNgrtfE/iuzBw+SPCFObdNID5X4u5cXTskhGPFcvrDKPD3bn\nEN56RGz7PHhs1+2OpDaWlAcwtatdIXgls2cB9a3PKiYITMBfQojBJqC9eDMA+6ZN\nl7NtmMxxCZWFjfizKUBmP9O783LxuMhtZLAEt2uI1iMlJPdrYPxrl8ACzUeRNHTL\nFtJCdekeRUmQOOQdYsouYvtCuZlfbVJhTvEMVzS8FjlZ6SKUL9CD/kYCq310GaPn\nNxcfJacFAgMBAAECggEAFWs/RxeAM1nkoMUVZ1U+3vOTZiBsNte1pw5YuWUo7qD/\nesAAlPfrsIqPVoAE60qaz/etW8CwhDh2zyEygs+iXeeylvmfFA8fA3kPvO4egVfw\naHBSaCEn+SwikCjWxY3KeMZkTt7K9dSWDH7AhIoZUXAscn8M/NlKKVWLsQXHMaL1\nbHL0kxbRUWvTlbY3kfyOXzqsbis69iZsJ6iBnIg6H0H2UaNpJ3ReS/7lB4RCSyWG\nxhexQJtJohRAtSX93v7h545xvoAFJodXI33VNcRgXP5Mx5+fvJJt5qqycF5jnXQ7\njhTNFbKBeYhAJaDFl+GvVpj5+vq8rlecmtyCtLYrDQKBgQDdmVzq+lBmJAWaNX+l\nLjYH67hld/NPYq7Cm3jNV+tkDomlrnVZQM5WAhjF9h7vt3cNNkDVBjRMLkAQUmUc\nkHlmRaVu9ap8qyZnP2LcrQA+JxjfzEwm408QZcz0D39x40tx82HXtdXraKXSWwnU\nrCvIUoWY+fDNkyuacs/ndhSpgwKBgQDYTmHayUeij0Ycyw588o43Jt6e87bo92kv\n10ADG7oWjVE0QBLBs2MnTAnJ+hltfwjylKcazgFJlMbO/l2LiDWDa7Jq1Y16ziKe\n6kqGCg01Lg8oK+w29EZiOjTx0mRlBeuvYjObWkZx/mNnPSABXE+Xf5+D9O8DBhsc\n3kE6wCdu1wKBgQCNGdRCgvSitRkkIiCPCye4T23wnjo9ODbTD7ASAIOQCHm5F6b9\nF/jKZzdjBd6ZARc7QGpzuimewGxmeDCNyaijaIF4b9EI5OnlIEVRAo9/A+IgzrNG\np8J2THv+g8fAutwVSMXqVoxKAy5jDTjrRF30hicvSyb7n1RKWgTr+xIZBQKBgQC0\nLpbU6VYC09ZTpdIrwuE0j+xh/CIhbfbxIxzveelJX+6E19rH/+ZYlb6RwQPtciTB\n7ZJFgdUQth3lz32c/ZmWH+A/niR8Z7nvJrttbHIUGooFrJDYNiNrL5Fq3xdCD+yD\n7AmRH2IPExk6pnBCseKbEHSQNzfiDPQI2Br+FZLDgQKBgQDU+RNtt1tbr8yC2oXG\nAox0+bZs55uWZ5EptdLhb0jnitGDiFtMtBPVswxcoJtPt9lFGAVv6PGZbKRZXZQd\nUrOBztdofRt9jaEEXgee5WTOy2pobfurkRRmIGRiBs8XvGl5nEP98wnGYfGGMI1y\nXBpqi3OhOv3CS1RrNVHiJyLlow==\n-----END PRIVATE KEY-----\n",
      "client_email": "fcmtextnotification@ekspedisisinarjaya.iam.gserviceaccount.com",
      "client_id": "104951981491911039831",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/fcmtextnotification%40ekspedisisinarjaya.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    };
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging"
    ];
    http.Client client = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );
    auth.AccessCredentials credentials =
    await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client);
    client.close();
    return credentials.accessToken.data;
  }

  static Future<void> sendNotification(
      String deviceToken, String title, String body) async {
    final String accessToken = await getAccessToken();
    String endpointFCM =
        'https://fcm.googleapis.com/v1/projects/ekspedisisinarjaya/messages:send';
    final Map<String, dynamic> message = {
      "message": {
        "token": deviceToken,
        "notification": {"title": title, "body": body},
        "data": {
          "route": "serviceScreen",
        }
      }
    };

    final http.Response response = await http.post(
      Uri.parse(endpointFCM),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken'
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification : ${response.body}');

    }
  }
}
