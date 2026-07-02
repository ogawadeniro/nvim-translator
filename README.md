# 動作要件
* 依存アプリケーション  
curl: 翻訳APIを呼び出すために必要  

* サポート対象バージョン  
Neovim のみ  
Neovim version >= 0.9.0  

# 機能
nvim-translator は、非同期実装のAPI翻訳サポートツールです。  
簡単な設定でNeovim上での翻訳を可能にします。  
サポート対象の翻訳APIプロバイダから選択して、自前のAPIキー、APIエンドポイントを設定するだけです。
翻訳中はイカしたロードスピナーが表示されます。

# サポート対象のAPIプロバイダ
- deepl(推奨)  
    速度、精度的にdeeplを推しています  
    リファレンス: https://developers.deepl.com/api-reference/translate  

- gemini
    Geminiに翻訳用のプロンプトを送信しています。  
    リファレンス: https://ai.google.dev/api  

# クイックスタート

* vim.pack

``` lua
vim.pack.add({
    { src = 'rogawa14106/nvim-translator' }
})

require('nvim-translator').setup({
    client = {
        -- deeplを使用する例(推奨)
        provider = "deepl",
        url = "https://api-free.deepl.com/v2/translate",
        api_key = "YOUR_API_KEY"
        }
    })
}
```

* Lazy  

``` lua
return {
    'rogawa14106/nvim-translator',
    config = function()
        require('nvim-translator').setup({
            client = {
                -- geminiを使用する例(推奨はdeepl)
                provider = "gemini",
                url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent",
                api_key = "YOUR_API_KEY"
            }
        })
    end,
}
```

# 使い方
- 翻訳  
1. ビジュアルモードで翻訳したいテキストを選択する  
2. 設定済みのキーマップを押す  


# デフォルトキーマップ
- visualモード

    |モード|キー|動作|
    |--|--|--|
    |v| \<Leader\>? | en → ja 翻訳 |
    |v| \<Leader\>g? | ja → en 翻訳 |

- 翻訳ウィンドウキーマップ  

    |モード|キー|動作|
    |--|--|--|
    |n| \<C-a\> | 翻訳結果をコピー |
    |n| \<q\> | ウィンドウを閉じる |

# 設定

``` lua
require('nvim-translator')setup({
    -- keymap設定
    -- 以下はデフォルト設定のため、カスタムしない場合は設定不要です
    keymap = {
        {
            -- visualモードで翻訳を発火する任意のキーを指定できます。
            key = "<Leader>?",
            -- 翻訳元(src)、翻訳先(dst)は、deeplの指定方法を参考に型付けしてます。
            src = "en",
            dst = "ja",
        },
        {
            key = "<Leader>g?",
            src = "ja",
            dst = "en",
        }
    },
    -- 翻訳APIクライアント設定
    client = {
        -- プロバイダーは"deepl" | "gemini"です。
        -- 推奨はdeeplです
        provider = "deepl",
        url = "https://api-free.deepl.com/v2/translate",
        api_key = "YOUR_API_KEY"
        }
    })
})
```
