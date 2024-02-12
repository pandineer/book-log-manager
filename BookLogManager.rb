require 'csv'
require 'rexml/document'
require 'set'

class BookLogManager
  def generate_diff_csv
    # Booklog からエクスポートした CSV をロードし、ASIN の set を作る
    # TODO: ファイル名のハードコードをやめる
    booklog_csv = CSV.read('booklog20240212090944.csv', encoding: 'Shift_JIS:UTF-8')
    booklog_asin_set = Set.new
    booklog_csv.each do |row|
      booklog_asin_set.add(row[1])
    end

    # KindleSyncMetadataCache.xml をロードする
    # TODO: ファイル名のハードコードをやめる
    file = File.open('KindleSyncMetadataCache.xml')
    kindle_sync_metadata_cache = REXML::Document.new(file)
    file.close
    kindle_contents = kindle_sync_metadata_cache.elements['response/add_update_list'].to_a

    # KindleSyncMetadataCache.xml から Booklogにすでに登録済みのASINを持つデータを除き、booklog インポート用のCSVを生成する
    # サービスID, アイテムID, 13桁ISBN, カテゴリ, 評価, 読書状況, レビュー, タグ, 読書メモ(非公開), 登録日時, 読了日
    # 追加で、自分の管理用のタイトルと購入日を出力する
    booklog_import_csv = CSV.open('booklog_import.csv', 'w')
    booklog_import_csv << ['サービスID', 'アイテムID', '13桁ISBN', 'カテゴリ', '評価', '読書状況', 'レビュー', 'タグ', '読書メモ(非公開)', '登録日時', '読了日']
    added_contents = kindle_contents.reject { |kindle_content| booklog_asin_set.include?(kindle_content.elements['ASIN'].text)}
    added_contents.each do |added_content|
      booklog_import_csv << [
        '1', # サービスID
        added_content.elements['ASIN'].text, # アイテムID
        '', # 13桁ISBN
        '', # カテゴリ
        '', # 評価
        '', # 読書状況
        '', # レビュー
        '', # タグ
        '', # 読書メモ(非公開)
        '', # 登録日時
        '', # 読了日
        added_content.elements['title'].text,
        added_content.elements['purchase_date'].text
      ]
    end
    booklog_import_csv.close
  end
end

book_log_manager = BookLogManager.new
book_log_manager.generate_diff_csv
