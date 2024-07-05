#include <stdio.h>
#include <stdlib.h>
#include <libgen.h>
#include <string.h>
#include <unistd.h>

#include <curl/curl.h>

const char* sofname = "odl";
const char* version = "0.3.1";
const char* avalopt = "nopv";
char* filename;

int opt;
int yokou_flag = 0;
int output_flag = 0;
int version_flag = 0;
int already_flag = 0;
int err_flag = 0;
int dlstat = 0;
int onedlsuc = 0;

char* get_filename(const char* url) {
  char* fn_start = strrchr(url, '/');
  if (fn_start == NULL) {
    return NULL;
  }
  fn_start++;

  char* query = strchr(fn_start, '?');
  char* anchor = strchr(fn_start, '#');
  char* fn_end = NULL;

  if (query != NULL && anchor != NULL) {
    fn_end = (query < anchor) ? query : anchor;
  } else if (query != NULL) {
    fn_end = query;
  } else if (anchor != NULL) {
    fn_end = anchor;
  }

  // URLでパラメートルがなければ、そのままファイル名をコピーして
  if (fn_end == NULL) {
    fn_end = strchr(fn_start, '\0');
  }

  size_t length = fn_end - fn_start;

  char* extfn = malloc(length + 1);
  if (extfn == NULL) {
    return NULL;
  }

  strncpy(extfn, fn_start, length);
  extfn[length] = '\0';

  return extfn;
}

int progress_callback(void *cp, double dt, double dn, double ut, double un) {
  (void)cp;
  (void)ut;
  (void)un;

  double progress = (dn / dt) * 100.0;

  printf("\r[");
  int barw = 50;
  int pos = (int)(progress * barw / 100.0);

  for (int i = 0; i < barw; ++i) {
    if (i < pos) printf("=");
    else if (i == pos) printf(">");
    else printf(" ");
  }

  printf("] %.2f%% %s", progress, filename);
  fflush(stdout);

  return 0;
}

void handle_o(int argc, char* argv[]) {
  output_flag = 1;
  if (optind < argc) {
    if (filename != NULL) {
      fprintf(
        stderr,
        "-oをご利用する場合、1つのファイルだけをダウンロード出来ます。\n"
      );
    }
    filename = argv[optind];
  } else {
    fprintf(stderr, "-oの後でファイル名がありません。");
    err_flag = 1;
  }
}

void dlsucmsg() {
  if (yokou_flag == 0) printf("\nダウンロードに完了しました。\n");
  else {
    printf("\nダウンロードに完了しました。\n");
    printf("予行演習モードですので、ファイルを保存していません。\n");
    printf("保存するには、「-n」フラグを消して下さい。\n");
  }
}

void usage() {
  printf("%s-%s\nusage: %s [-%s] [url ...]\n", sofname, version, sofname, avalopt);
}

void flags(int opt, int argc, char* argv[]) {
  switch (opt) {
    case 'n':
      yokou_flag = 1;
      break;
    case 'o':
      handle_o(argc, argv);
      break;
    case 'p':
      already_flag = 1;
      break;
    case 'v':
      version_flag = 1;
      break;
    default:
      err_flag = 1;
      usage();
      break;
  }
}

int downloader(CURL* curl, char* filename, const char* url) {
  if (already_flag == 1 && access(filename, F_OK) != -1) {
    printf("ファイルが既に存在しますので、ダウンロードしません。\n");
    return 1;
  }

  curl_easy_setopt(curl, CURLOPT_URL, url);

  // Clownflareは面倒くさいわね・・・
  curl_easy_setopt(
    curl,
    CURLOPT_USERAGENT,
    "Mozilla/5.0 (Windows NT 10.0; rv:102.0) Gecko/20100101 Firefox/102.0"
  );
  // Pixivも結構面倒くさい
  if (
      strstr("s.pixiv.net", url) == 0 ||
      strstr("i.pixiv.net", url) == 0 ||
      strstr("s.pximg.net", url) == 0 ||
      strstr("i.pximg.net", url) == 0
  ) {
    curl_easy_setopt(curl, CURLOPT_REFERER, "https://www.pixiv.net/");
  }

  curl_easy_setopt(curl, CURLOPT_PROGRESSFUNCTION, progress_callback);
  curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);

  FILE* file = NULL;

  if (yokou_flag == 0) {
    file = fopen(filename, "wb");
  } else {
    file = fopen("/tmp/odl_test", "wb");
  }

  if (!file) {
    perror("ファイルを開けません。");
    curl_easy_cleanup(curl);
    return -1;
  }

  curl_easy_setopt(curl, CURLOPT_WRITEDATA, file);

  long httpcode = 0;
  CURLcode res = curl_easy_perform(curl);
  curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpcode);

  fclose(file);
  if (yokou_flag == 1) unlink("/tmp/odl_test");

  if (res != CURLE_OK) {
    if (yokou_flag == 0) unlink(filename);
    fprintf(stderr, "\nダウンロードに失敗： %s\n", curl_easy_strerror(res));
    return -1;
  }

  if (res == CURLE_ABORTED_BY_CALLBACK || httpcode != 200) {
    if (yokou_flag == 0) unlink(filename);
    fprintf(stderr, "\n%sをダウンロードに失敗： HTTP CODE: %ld\n", filename, httpcode);
    return -1;
  }

  printf("\n");

  return 0;
}

int main(int argc, char* argv[]) {
  if (argc < 2) {
    usage();
    return 1;
  }

  while ((opt = getopt(argc, argv, avalopt)) != -1) {
    flags(opt, argc, argv);
  }

  if (err_flag == 1) {
    return 1;
  }

  if (version_flag == 1) {
    printf("%s-%s\n", sofname, version);
    return 0;
  }

  CURL* curl = curl_easy_init();
  if (!curl) {
    perror("curlを初期設置に失敗。");
    return -1;
  }

  // 一つのファイルだけが可能
  if (output_flag == 1) {
    if (optind >= argc) {
      fprintf(stderr, "-oの後でURLがありません。");
      return 1;
    }

    if (filename == NULL) {
      fprintf(stderr, "-oの後でファイル名がありません。");
      return 1;
    }

    filename = argv[optind];
    const char* url = argv[optind+1];
    dlstat = downloader(curl, filename, url);
    if (dlstat == 0) onedlsuc = 1;

    curl_easy_cleanup(curl);

    if (onedlsuc == 1) {
      dlsucmsg();
      return 0;
    }

    return 1;
  }

  // 複数ファイル名可能
  for (int i = optind; i < argc; i++) {
    const char* url = argv[i];
    filename = get_filename(url);
    if (filename == NULL) {
      fprintf(stderr, "URLからファイル名を抽出出来ませんでした。\n");
      continue;
    }

    dlstat = downloader(curl, filename, url);
    if (dlstat == 0) onedlsuc = 1;
  }

  curl_easy_cleanup(curl);
  if (onedlsuc == 1) {
    dlsucmsg();
    return 0;
  }

  return 1;
}
