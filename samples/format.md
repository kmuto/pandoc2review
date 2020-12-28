レベル1ヘッダ
============

<http://sky-y.github.io/site-pandoc-jp/users-guide/> を参考にする

レベル2ヘッダ
------------

### レベル3ヘッダ ###

### ヘッダの後ろにはいくらでも`#`を付けてもよい ######

# 見出し1
## 見出し2
### 見出し3
#### 見出し4
##### 見出し5
###### 見出し6

# ヘッダ {#foo}
# ヘッダ {-}
# ヘッダ {.unnumbered}

段落1
の継続行

段落2

- リスト1
  - リスト1-1
    - リスト1-1-1
    - リスト1-1-2
  - リスト1-2
- リスト2

1. 番号リスト1
   1. 番号リスト1-1
   1. 番号リスト1-2
1. 番号リスト2

> 引用1
>
> 引用2
> > 二重引用

二重引用がうまくいかない。

    class Hoge
    end

```haskell
qsort [] = []
```

``` {.haskell}
qsort [] = []
```

| The Right Honorable Most Venerable and Righteous Samuel L.
  Constable, Jr.
| 200 Main St.
| Berkeley, CA 94718

* フルーツ
    + りんご
        - サンふじ
        - 紅玉
    + なし
    + もも
* 野菜
    + ブロッコリー
    + セロリ

#. ひとつめ
#. ふたつめ

 9)  Ninth
10)  Tenth
11)  Eleventh
       i. subone
      ii. subtwo
     iii. subthree

用語1

:   定義1

*インラインマークアップ*の入った用語2

:   定義2

        { コード、定義2の一部 }

    定義2の3つ目の段落。

これは[リンクです][FOO]

[Foo]: /bar/baz

インストールコマンドは `gem insall hoge` です。_EM_ですね。*EM*ですね。
**BOLD**ですね。__BOLD__ですね。***ITBOLD***ですね。___ITBOLD___ですね。

pandocだとスペースないと _EM_ 、 __BOLD__ 、 ___ITBOLD___ はだめっぽい。

Re:VIEWのインラインエスケープ __int{}__ $f=int_{1}^{n}$

***

---

[Google](https://www.google.co.jp/)

[こっちからgoogle][Google]
その他の文章
[こっちからもgoogle][Google]
これはうまくいかないようだ。

~~取り消し~~

~~~
class Hoge
end
~~~

```{caption="ほげほげ"}
class Hoge
end
```

|header1|header2|header3|
|:--|--:|:--:|
|align left|align right|align center|
|a|b|c|

---

表2

  Right     Left     Center     Default
-------     ------ ----------   -------
     12     12        12            12
    123     123       123          123
      1     1          1             1

Table:  シンプルテーブルのデモ

* [to header1](#header1)
* [to header2](#header2)

[return to menu](#menu)

*\*hello\**

H~2~O は液体です。2^10^ は 1024 です。

`<$>`{.haskell}

<h1>HOGE!</h1>

<http://google.com>
<sam@green.eggs.ham>

![ラ・ルーン](lalune.jpg "月への旅行")

![ラ・ルーン](lalune.jpg)

![](lalune.jpg)

![](./images/hoge.lalune.jpg)

これは脚注の参照です[^1]、 そしてもう1つ[^longnote]。

[^1]: これは脚注です。

[^longnote]: これは長いブロックから成る脚注です。

    インデントされたいくつかの段落が続くと、
それらは前の脚注に含まれます。

        { some.code }

    段落の全体または1行目がインデントされていればOKです。このように、
    複数の段落による脚注は複数項目のリストアイテムのように機能します。

この段落は脚注ではありません。なぜならインデントされていないからです。

これはインライン脚注です。^[識別子をわざわざ探して打つ必要が無いため、
インライン脚注は楽に書けます。]

<div class="note">
HEY! <span class="A">hoge</span>
</div>

'はどうなる？ **'はどうなる？**
’はどうなる？ **’はどうなる？**
`はどうなる？
**`はどうなる？**
\はどうなる？ **\はどうなる？**
--はどうなる？ **--はどうなる？**
–はどうなる？ **–はどうなる？**
---はどうなる？ **---はどうなる？**
—はどうなる？ **—はどうなる？**

```
code内 '` \ -- --- ’ – —
```

## 見出し内 '` \ -- --- ’ – —
