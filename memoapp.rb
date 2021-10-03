require 'sinatra'
require 'net/http'
require 'uri'
require 'json'
require 'bundler'

Bundler.require

memo_hash = {}

get '/memos/top' do
  File.open("memos.json") do |j|
    memo_hash = JSON.load(j)
  end

  @t = ""
  if memo_hash["memos"].length == 0
    @t = "<p>メモがありません</p>"
  else
    i = 0
    memo_hash["memos"].length.times do
      @t = @t + "<a href=\"/memos/#{memo_hash["memos"][i]["id"]}/show\"><p>#{memo_hash["memos"][i]["title"]}</p><br>"
      i += 1
    end
  end
  @t = @t + "<a href=\"/new\">追加</a>"
  erb :top
end

get '/memos/:id/show' do
  # URLからクリックしたメモのタイトルに対応するIDを取得し
  # 表示するメモを指定するインデックスとして設定
  id = params[:id]
  memo_index = id.to_i - 1

  File.open("memos.json") do |j|
    memo_hash = JSON.load(j)
  end

  @t = ""
  @t = @t + "<h2>#{memo_hash["memos"][memo_index]["title"]}</h2>"
  @t = @t + "<p>#{memo_hash["memos"][memo_index]["contents"]}</p>"
  @t = @t + "<a href=\"/memos/#{id}/edit\">編集</a><br>"
  @t = @t + "<form action=\"/memos/#{id}/del\" method=\"post\">"
  @t = @t + "<input type=\"submit\" value=\"削除\">"
  @t = @t + "<input type=\"hidden\" name=\"id\" value=\"#{id}\">"
  @t = @t + "<input type=\"hidden\" name=\"_method\" value=\"delete\">"
  @t = @t + "</form>"

  erb :show
end

get '/new' do
  erb :new
end

post '/new_' do
  # JSONファイルに格納されているメモデータを全て取得しハッシュに格納
  File.open('memos.json') do |j|
    memo_hash = JSON.load(j)
  end

  max_id = 0
  memo_hash["memos"].each do |memo|
    # 格納されているメモの中で最大のIDを求め、その数値+1を新しく追加するメモのIDとする
    if memo['id'].to_i > max_id
      max_id = memo['id'].to_i
    end
  end
  max_id += 1
  # 新規画面で入力したメモのタイトルと内容をハッシュに格納する
  memo_hash["memos"].push({"id":max_id.to_s,"title":params[:title],"contents":params[:contents]})

  # JSONファイルを開いてハッシュの内容を上書き
  File.open("memos.json", "w") do |file|
    JSON.dump(memo_hash, file)
  end
  redirect '/memos/top'
end

get '/memos/:id/edit' do
  id = params[:id]

  File.open("memos.json") do |j|
    memo_hash = JSON.load(j)
  end

  @t = ""
  i = 0
  memo_hash["memos"].length.times do
    if memo_hash["memos"][i]["id"] == id
      # URLに含まれているメモIDと一致するIDをハッシュから探し出し、編集画面のタイトルと内容のテキストに表示する
      @t = @t + "<form action=\"/edit_/#{id}\" method=\"post\">"
      @t = @t + "<input id=\"hidden\" type=\"hidden\" name=\"_method\" value=\"patch\">"
      @t = @t + "<h2>タイトル</h2><br>"
      @t = @t + "<input type=\"text\" size=\"30\" maxlength=\"20\" value=\"#{memo_hash["memos"][i]["title"]}\" name=\"title\"><br>"
      @t = @t + "<h3>内容</h3><br>"
      @t = @t + "<textarea cols=\"40\" rows=\"20\" maxlength=\"100\" name=\"contents\">#{memo_hash["memos"][i]["contents"]}</textarea><br>"
      @t = @t + "<input type=\"submit\" value=\"保存\">"
      @t = @t + "</form>"
      @t = @t + "<a href=\"/memos/#{id}/show\">キャンセル</a>"
      break
    end
    i += 1
  end

  erb :edit
end

patch '/edit_/:id' do
  # URLから編集するメモのデータを取り出す
  id = params[:id]
  title = params[:title]
  contents = params[:contents]

  File.open("memos.json") do |j|
    memo_hash = JSON.load(j)
  end

  i = 0
  memo_hash["memos"].length.times do
    if i == (id.to_i - 1)
      # 配列のインデックスとメモID-1の値が等しければ、編集したタイトルと内容をハッシュに格納
      memo_hash["memos"][i]["title"] = title
      memo_hash["memos"][i]["contents"] = contents
      break
    end
    i += 1
  end

  # JSONファイルを開いてハッシュの内容を上書き
  File.open("memos.json", "w") do |file|
    JSON.dump(memo_hash, file)
  end

  redirect '/memos/' + id + '/show'
end

delete '/memos/:id/del' do
  # URLから削除するメモのIDを取り出し
  # 削除するメモのインデックスを指定
  id = params[:id].to_i
  memo_index = id - 1

  File.open("memos.json") do |j|
    memo_hash = JSON.load(j)
  end

  # 削除したメモデータから数えていくつ分のメモデータのIDを更新するかを求める
  times = memo_hash["memos"].length - memo_index - 1
  # 該当するインデックスのメモデータを削除
  memo_hash["memos"].delete_at(memo_index)

  # メモデータを削除した場合に、IDが中抜けになり整合が取れなくなるのを防ぐために
  # 削除したメモ以降のデータのIDを-1する
  i = 0
  if times != 0
    # timesが0(一番後ろのメモデータを削除)の場合は行わない
    times.times do
      memo_hash["memos"][memo_index]["id"] = memo_hash["memos"][memo_index]["id"].to_i - 1
      memo_index += 1
    end
  end

  File.open("memos.json", "w") do |file|
    JSON.dump(memo_hash, file)
  end

  redirect '/memos/top'
end