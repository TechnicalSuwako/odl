#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>

#include <curl/curl.h>

const char* sofname = "odl";
const char* version = "0.1.0";
char* filename;

int progress_callback(void *cp, double dt, double dn, double ut, double un) {
  (void)cp;
  (void)ut;
  (void)un;

  double progress = (dn / dt) * 100.0;
  char* status = "ダウンロード中";
  if (progress == 100.0) status = "ダウンロード済み";

  printf("\r[");
  int barw = 50;
  int pos = (int)(progress * barw / 100.0);

  for (int i = 0; i < barw; ++i) {
    if (i < pos) printf("=");
    else if (i == pos) printf(">");
    else printf(" ");
  }

  printf("] %.2f%% %s, %s", progress, filename, status);
  fflush(stdout);

  return 0;
}

int main(int argc, char* argv[]) {
  if (argc < 2) {
    printf("usage: %s [url ...]\n", sofname);
    return 1;
  }

  CURL* curl = curl_easy_init();
  if (!curl) {
    perror("curlを初期設置に失敗。");
    return -1;
  }

  for (int i = 1; i < argc; i++) {
    const char* url = argv[i];
    filename = basename((char*)url);

    curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, progress_callback);
    curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);

    FILE* file = fopen(filename, "wb");
    if (!file) {
      curl_easy_cleanup(curl);
      perror("ファイルを開けません。");
      return -1;
    }

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, file);
    CURLcode res = curl_easy_perform(curl);
    fclose(file);

    if (res != CURLE_OK) {
      curl_easy_cleanup(curl);
      fprintf(stderr, "ダウンロードに失敗： %s\n", curl_easy_strerror(res));
      return -1;
    }

    printf("\n");
  }

  curl_easy_cleanup(curl);

  printf("\nダウンロードに完了しました。\n");

  return 0;
}
