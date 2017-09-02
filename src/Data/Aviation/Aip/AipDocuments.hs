{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Data.Aviation.Aip.AipDocuments(
  AipDocuments(..)
, distributeAipDocuments
, writeAipDocuments
, requestAipDocuments
, getAipDocuments
) where

import Control.Monad.IO.Class(liftIO)
import Data.ByteString(ByteString)
import Data.Maybe(maybeToList)
import System.Directory(createDirectoryIfMissing)
import System.FilePath((</>))
import System.IO(Handle, IO, IOMode(AppendMode), withFile)
import Control.Monad.Trans.Except(ExceptT, runExceptT)
import Data.Aviation.Aip.AipDate(uriAipDate)
import Data.Aviation.Aip.AipDocument(AipDocument(AipDocument), requestAipDocument)
import Data.Aviation.Aip.ConnErrorHttp4xx(ConnErrorHttp4xx)
import Data.Aviation.Aip.Ersa(Ersa(Ersa))
import Data.Aviation.Aip.Ersas(Ersas(Ersas), parseAipTree)
import Data.Aviation.Aip.HttpRequest(requestAipContents, aipRequestGet)
import Network.BufferType(BufferType)
import Papa

newtype AipDocuments ty =
  AipDocuments
    [AipDocument ty]
  deriving Show

makeWrapped ''AipDocuments

-- | Writes three log files; `err.log`, `out.log`, `aip`.
distributeAipDocuments ::
  FilePath -- ^ log error
  -> FilePath -- ^ log out
  -> IO [FilePath]
distributeAipDocuments adir ldir=
  let wlogfile f =
        liftIO . withFile (ldir </> f) AppendMode
  in  do  liftIO (mapM_ (createDirectoryIfMissing True) [adir, ldir])
          wlogfile "err.log" (\herr ->
            wlogfile "out.log" (\hout ->
              do  p <- runExceptT (writeAipDocuments herr hout adir)
                  mapM_ (\qs -> appendFile (ldir </> "aip") (qs >>= \q -> q ++ "\n")) p
                  pure (either (const []) id p)))

writeAipDocuments ::
    Handle -- ^ log error
  -> Handle -- ^ log out
  -> FilePath
  -> ExceptT ConnErrorHttp4xx IO [FilePath]
writeAipDocuments errlog outlog dir =
  requestAipContents >>= liftIO . requestAipDocuments errlog outlog . getAipDocuments dir . parseAipTree

requestAipDocuments ::
  Handle -- ^ log error
  -> Handle -- ^ log out
  -> AipDocuments ByteString
  -> IO [FilePath]
requestAipDocuments errlog outlog (AipDocuments ds) =
  (>>= maybeToList) <$> mapM (requestAipDocument errlog outlog) ds

getAipDocuments ::
  BufferType ty =>
  FilePath -- output directory 
  -> Ersas
  -> AipDocuments ty
getAipDocuments dir (Ersas ersas) =
  let simpleAipDocuments =
        [
      --  AIP Book
          "aip/complete.pdf"
        , "aip/general.pdf"
        , "aip/enroute.pdf"
        , "aip/aerodrome.pdf"
        , "aip/cover.pdf"
        , "aip/index.pdf"
      --  AIP Charts (current)
        , "aipchart/erch/erch1.pdf"
        , "aipchart/erch/erch2.pdf"
        , "aipchart/erch/erch3.pdf"
        , "aipchart/erch/erch4.pdf"
        , "aipchart/erch/erch5.pdf"
        , "aipchart/ercl/ercl1.pdf"
        , "aipchart/ercl/ercl2.pdf"
        , "aipchart/ercl/ercl3.pdf"
        , "aipchart/ercl/ercl4.pdf"
        , "aipchart/ercl/ercl5.pdf"
        , "aipchart/ercl/ercl6.pdf"
        , "aipchart/ercl/ercl7.pdf"
        , "aipchart/ercl/ercl8.pdf"
        , "aipchart/pca/PCA_back.pdf"
        , "aipchart/pca/PCA_front.pdf"
        , "aipchart/tac/tac1.pdf"
        , "aipchart/tac/tac2.pdf"
        , "aipchart/tac/tac3.pdf"
        , "aipchart/tac/tac4.pdf"
        , "aipchart/tac/tac5.pdf"
        , "aipchart/tac/tac6.pdf"
        , "aipchart/tac/tac7.pdf"
        , "aipchart/tac/tac8.pdf"
        , "aipchart/vnc/Adelaide_VNC.pdf"
        , "aipchart/vnc/Brisbane_VNC.pdf"
        , "aipchart/vnc/Bundaberg_VNC.pdf"
        , "aipchart/vnc/Cairns_VNC.pdf"
        , "aipchart/vnc/Darwin_VNC.pdf"
        , "aipchart/vnc/Deniliquin_VNC.pdf"
        , "aipchart/vnc/Hobart_VNC.pdf"
        , "aipchart/vnc/Launceston_VNC.pdf"
        , "aipchart/vnc/Melbourne_VNC.pdf"
        , "aipchart/vnc/Newcastle_VNC.pdf"
        , "aipchart/vnc/Perth_VNC.pdf"
        , "aipchart/vnc/Rockhampton_VNC.pdf"
        , "aipchart/vnc/Sydney_VNC.pdf"
        , "aipchart/vnc/Tindal_VNC.pdf"
        , "aipchart/vnc/Townsville_VNC.pdf"
        , "aipchart/vtc/Adelaide_VTC.pdf"
        , "aipchart/vtc/Albury_VTC.pdf"
        , "aipchart/vtc/AliceSprings_Uluru_VTC.pdf"
        , "aipchart/vtc/Brisbane_Sunshine_VTC.pdf"
        , "aipchart/vtc/Broome_VTC.pdf"
        , "aipchart/vtc/Cairns_VTC.pdf"
        , "aipchart/vtc/Canberra_VTC.pdf"
        , "aipchart/vtc/Coffs_Harbour_VTC.pdf"
        , "aipchart/vtc/Darwin_VTC.pdf"
        , "aipchart/vtc/Gold_Coast_VTC.pdf"
        , "aipchart/vtc/Hobart_VTC.pdf"
        , "aipchart/vtc/Karratha_VTC.pdf"
        , "aipchart/vtc/Launceston_VTC.pdf"
        , "aipchart/vtc/Mackay_VTC.pdf"
        , "aipchart/vtc/Melbourne_VTC.pdf"
        , "aipchart/vtc/Newcastle_Williamtown_VTC.pdf"
        , "aipchart/vtc/Oakey_Bris_VTC.pdf"
        , "aipchart/vtc/perth_legend.pdf"
        , "aipchart/vtc/Perth_VTC.pdf"
        , "aipchart/vtc/Rockhampton_VTC.pdf"
        , "aipchart/vtc/Sydney_VTC.pdf"
        , "aipchart/vtc/Tamworth_VTC.pdf"
        , "aipchart/vtc/Townsville_VTC.pdf"
        , "aipchart/vtc/Whitsunday_VTC.pdf"
      -- DAP
        , "dap/SpecNotManTOC.htm"
        , "dap/ChecklistTOC.htm"
        , "dap/LegendInfoTablesTOC.htm"
        , "dap/AeroProcChartsTOC.htm"
      -- DAH
        , "dah/dah.pdf"
      -- Precision Approach Terrain Charts and Type A & Type B Obstacle Charts
        , "chart/TypeAandBCharts.pdf"
        ]
      ersaprelim =
        [
          "GUID_ersa-fac-1-3"
        , "GUID_ersa-fac-1-4"
        , "GUID_ersa-fac-1-5"
        , "PRD_"
        , "LND_"
        , "IFR_"
        , "VFR_"
        , "GUID_ersa-fac-2-2"
        , "GUID_ersa-fac-2-3"
        , "GUID_ersa-fac-2-4"
        , "GUID_ersa-fac-2-5"
        , "GUID_ersa-fac-2-6"
        , "GUID_ersa-fac-2-7"
        , "GUID_ersa-fac-2-8"
        , "GUID_ersa-fac-2-9"
        , "GUID_ersa-fac-2-10"
        , "GUID_ersa-fac-2-11"
        , "GUID_ersa-fac-2-12"
        , "GUID_ersa-fac-2-14"
        ]
      ersafac =
        [
          "FAC_YADY"
        , "FAC_ADAC"
        , "FAC_YPAD"
        , "FAC_YPPF"
        , "FAC_YALG"
        , "FAC_YABA"
        , "FAC_YMAY"
        , "FAC_YADG"
        , "FAC_YBAS"
        , "FAC_YAPH"
        , "FAC_YAMT"
        , "FAC_YAMB"
        , "FAC_YANK"
        , "FAC_YAMC"
        , "FAC_YARA"
        , "FAC_YARS"
        , "FAC_YARG"
        , "FAC_YARK"
        , "FAC_YARM"
        , "FAC_YARY"
        , "FAC_YATN"
        , "FAC_YAUG"
        , "FAC_YAGD"
        , "FAC_YAUR"
        , "FAC_YMAV"
        , "FAC_YAYE"
        , "FAC_YAYR"
        , "FAC_YBSS"
        , "FAC_YBAU"
        , "FAC_YBNS"
        , "FAC_YBLC"
        , "FAC_YBGO"
        , "FAC_YBLT"
        , "FAC_YLLE"
        , "FAC_YBIU"
        , "FAC_YBNA"
        , "FAC_YBRN"
        , "FAC_YBMY"
        , "FAC_YBAD"
        , "FAC_YBAB"
        , "FAC_YBAR"
        , "FAC_YBRY"
        , "FAC_YBWX"
        , "FAC_YBRS"
        , "FAC_YBYL"
        , "FAC_YBTH"
        , "FAC_YBTI"
        , "FAC_YBFT"
        , "FAC_YBIE"
        , "FAC_YBEB"
        , "FAC_YBLU"
        , "FAC_YBLA"
        , "FAC_YBDG"
        , "FAC_YBEO"
        , "FAC_YBEE"
        , "FAC_YBYS"
        , "FAC_YBHL"
        , "FAC_YBIR"
        , "FAC_YBDV"
        , "FAC_YBCK"
        , "FAC_YBTR"
        , "FAC_YBLP"
        , "FAC_YBOI"
        , "FAC_YBLL"
        , "FAC_YBOM"
        , "FAC_YBOC"
        , "FAC_YBGD"
        , "FAC_YBMI"
        , "FAC_YBOA"
        , "FAC_YBBT"
        , "FAC_YBOR"
        , "FAC_YBRL"
        , "FAC_YBOU"
        , "FAC_YBKE"
        , "FAC_YBWN"
        , "FAC_YBPI"
        , "FAC_YBRW"
        , "FAC_YBGR"
        , "FAC_BNAC"
        , "FAC_YBWW"
        , "FAC_YBBN"
        , "FAC_YBAF"
        , "FAC_YBHI"
        , "FAC_BML"
        , "FAC_YBRM"
        , "FAC_YBUN"
        , "FAC_YBUD"
        , "FAC_YBKT"
        , "FAC_YBLN"
        , "FAC_YCAB"
        , "FAC_YCDH"
        , "FAC_YCAG"
        , "FAC_YBCS"
        , "FAC_YCDR"
        , "FAC_YCVG"
        , "FAC_YSCN"
        , "FAC_YCMH"
        , "FAC_YCMW"
        , "FAC_YSCB"
        , "FAC_YCLQ"
        , "FAC_YCEL"
        , "FAC_YCAV"
        , "FAC_YCDW"
        , "FAC_YCAR"
        , "FAC_YCAS"
        , "FAC_YCTN"
        , "FAC_YCDU"
        , "FAC_YCNY"
        , "FAC_YCES"
        , "FAC_YCNK"
        , "FAC_YBCV"
        , "FAC_YCHT"
        , "FAC_YCGO"
        , "FAC_YCCA"
        , "FAC_YCHK"
        , "FAC_YPXM"
        , "FAC_YCVA"
        , "FAC_YCMT"
        , "FAC_YCEE"
        , "FAC_YCFN"
        , "FAC_YCCY"
        , "FAC_YUNY"
        , "FAC_YCBA"
        , "FAC_YCDE"
        , "FAC_YCCT"
        , "FAC_YPCC"
        , "FAC_YCOE"
        , "FAC_YCFS"
        , "FAC_YCOH"
        , "FAC_YOLA"
        , "FAC_YCEM"
        , "FAC_YCBR"
        , "FAC_YCSV"
        , "FAC_YCDO"
        , "FAC_YCBP"
        , "FAC_YCOO"
        , "FAC_YCKN"
        , "FAC_YCAH"
        , "FAC_YCXA"
        , "FAC_YPFT"
        , "FAC_YCOM"
        , "FAC_YBCM"
        , "FAC_YCBB"
        , "FAC_YCNM"
        , "FAC_YCWA"
        , "FAC_YCTM"
        , "FAC_YCOR"
        , "FAC_YCRG"
        , "FAC_YCWL"
        , "FAC_YCWR"
        , "FAC_YCRN"
        , "FAC_YCKI"
        , "FAC_YCRL"
        , "FAC_YCRY"
        , "FAC_YCUE"
        , "FAC_YCMM"
        , "FAC_YCUN"
        , "FAC_YCMU"
        , "FAC_YCIN"
        , "FAC_YDAY"
        , "FAC_YDLO"
        , "FAC_YDNI"
        , "FAC_DNAC"
        , "FAC_YPDN"
        , "FAC_YDPD"
        , "FAC_YDGU"
        , "FAC_YDWF"
        , "FAC_YDLV"
        , "FAC_YDLT"
        , "FAC_YDLQ"
        , "FAC_YDEK"
        , "FAC_YDBY"
        , "FAC_YDPO"
        , "FAC_YDBI"
        , "FAC_YDOC"
        , "FAC_YDVR"
        , "FAC_YDOD"
        , "FAC_YDOP"
        , "FAC_YDMG"
        , "FAC_YDOR"
        , "FAC_YDRN"
        , "FAC_YDRD"
        , "FAC_YSDU"
        , "FAC_YDKG"
        , "FAC_YDBR"
        , "FAC_YDKI"
        , "FAC_YDUN"
        , "FAC_YDRH"
        , "FAC_YDRI"
        , "FAC_YDYS"
        , "FAC_YEJI"
        , "FAC_YMES"
        , "FAC_YECH"
        , "FAC_YECB"
        , "FAC_YPED"
        , "FAC_YESD"
        , "FAC_YELD"
        , "FAC_YEQY"
        , "FAC_YELN"
        , "FAC_YESE"
        , "FAC_YEML"
        , "FAC_YMKT"
        , "FAC_YEMP"
        , "FAC_YENO"
        , "FAC_YEHP"
        , "FAC_YERN"
        , "FAC_YEMG"
        , "FAC_YESC"
        , "FAC_YESP"
        , "FAC_YEUO"
        , "FAC_YEUA"
        , "FAC_YEVD"
        , "FAC_YEXM"
        , "FAC_YFDN"
        , "FAC_YFTZ"
        , "FAC_YFLI"
        , "FAC_YFBS"
        , "FAC_YFRT"
        , "FAC_YFTA"
        , "FAC_YFDF"
        , "FAC_YFRG"
        , "FAC_YGAD"
        , "FAC_YGPT"
        , "FAC_YGAS"
        , "FAC_YGAW"
        , "FAC_YGAY"
        , "FAC_YGTO"
        , "FAC_YGTN"
        , "FAC_YGEL"
        , "FAC_YGIB"
        , "FAC_YGLS"
        , "FAC_YGIL"
        , "FAC_YGIA"
        , "FAC_YGIG"
        , "FAC_YGLA"
        , "FAC_YGLI"
        , "FAC_YGNB"
        , "FAC_YGLO"
        , "FAC_YBCG"
        , "FAC_YGGE"
        , "FAC_YGDA"
        , "FAC_YGWA"
        , "FAC_YGDI"
        , "FAC_YGLB"
        , "FAC_YPGV"
        , "FAC_YGFN"
        , "FAC_YGRS"
        , "FAC_YGKL"
        , "FAC_YGRL"
        , "FAC_YGDS"
        , "FAC_YGTH"
        , "FAC_YGTE"
        , "FAC_YGDO"
        , "FAC_YGDH"
        , "FAC_YGYM"
        , "FAC_YHAA"
        , "FAC_YHLC"
        , "FAC_YHML"
        , "FAC_YBHM"
        , "FAC_YHAW"
        , "FAC_YHAY"
        , "FAC_YHEC"
        , "FAC_YHCS"
        , "FAC_YHMB"
        , "FAC_YHBA"
        , "FAC_YHLS"
        , "FAC_YMHB"
        , "FAC_YCBG"
        , "FAC_YHBK"
        , "FAC_YSHW"
        , "FAC_YHON"
        , "FAC_YHOO"
        , "FAC_YHPN"
        , "FAC_YHID"
        , "FAC_YHSM"
        , "FAC_YHUG"
        , "FAC_YHRD"
        , "FAC_YIFY"
        , "FAC_YILF"
        , "FAC_YIGM"
        , "FAC_YINJ"
        , "FAC_YIKM"
        , "FAC_YINN"
        , "FAC_YIMT"
        , "FAC_YIFL"
        , "FAC_YIVL"
        , "FAC_YISF"
        , "FAC_YIVO"
        , "FAC_YJAB"
        , "FAC_YJAC"
        , "FAC_YJST"
        , "FAC_YJER"
        , "FAC_YJBY"
        , "FAC_YJIN"
        , "FAC_YJLC"
        , "FAC_YJDA"
        , "FAC_YJUN"
        , "FAC_YJNB"
        , "FAC_YKDI"
        , "FAC_YKBR"
        , "FAC_YPKG"
        , "FAC_YKKG"
        , "FAC_YKAL"
        , "FAC_YKBL"
        , "FAC_YKML"
        , "FAC_YKAR"
        , "FAC_YPKA"
        , "FAC_YKMB"
        , "FAC_YKNG"
        , "FAC_YKAT"
        , "FAC_YKMP"
        , "FAC_YKER"
        , "FAC_YKHO"
        , "FAC_YKDM"
        , "FAC_YKID"
        , "FAC_YKCY"
        , "FAC_YKLE"
        , "FAC_YIMB"
        , "FAC_YKKN"
        , "FAC_YKII"
        , "FAC_YKRY"
        , "FAC_YKCS"
        , "FAC_YKSC"
        , "FAC_YKIG"
        , "FAC_YKBN"
        , "FAC_YKOW"
        , "FAC_YKUB"
        , "FAC_YPKU"
        , "FAC_YKTN"
        , "FAC_YLCG"
        , "FAC_YLEV"
        , "FAC_YLJN"
        , "FAC_YKEP"
        , "FAC_YLMQ"
        , "FAC_YLKE"
        , "FAC_YLAK"
        , "FAC_YLCK"
        , "FAC_YLTV"
        , "FAC_YMLT"
        , "FAC_YLTN"
        , "FAC_YLAW"
        , "FAC_YLAH"
        , "FAC_YPLM"
        , "FAC_YLGU"
        , "FAC_YLEC"
        , "FAC_YLST"
        , "FAC_YLEG"
        , "FAC_YLEO"
        , "FAC_YLED"
        , "FAC_YLRD"
        , "FAC_YLIL"
        , "FAC_YLIS"
        , "FAC_YLZI"
        , "FAC_YLHR"
        , "FAC_YLCS"
        , "FAC_YLRE"
        , "FAC_YLHI"
        , "FAC_YLOR"
        , "FAC_YLOH"
        , "FAC_YLOX"
        , "FAC_YLYK"
        , "FAC_YMAA"
        , "FAC_YBMK"
        , "FAC_YMND"
        , "FAC_YMLD"
        , "FAC_YMCO"
        , "FAC_YMNG"
        , "FAC_YMGD"
        , "FAC_YMJM"
        , "FAC_YMFD"
        , "FAC_YMBL"
        , "FAC_YMBA"
        , "FAC_YMGT"
        , "FAC_YMGR"
        , "FAC_YALA"
        , "FAC_YMRE"
        , "FAC_YMYB"
        , "FAC_YMBU"
        , "FAC_YMHU"
        , "FAC_YMEK"
        , "FAC_MLAC"
        , "FAC_YMML"
        , "FAC_YMEN"
        , "FAC_YMMB"
        , "FAC_YMEL"
        , "FAC_YMET"
        , "FAC_YMEI"
        , "FAC_YMER"
        , "FAC_YMDN"
        , "FAC_YMMU"
        , "FAC_YMIA"
        , "FAC_YMLS"
        , "FAC_YMGB"
        , "FAC_YMIO"
        , "FAC_YMCT"
        , "FAC_YMMN"
        , "FAC_YMDR"
        , "FAC_YMPA"
        , "FAC_YMIB"
        , "FAC_YMIT"
        , "FAC_YITT"
        , "FAC_YMIG"
        , "FAC_YMMO"
        , "FAC_YMOD"
        , "FAC_YMNK"
        , "FAC_YMTO"
        , "FAC_YOOM"
        , "FAC_YMOO"
        , "FAC_YMRB"
        , "FAC_YMRW"
        , "FAC_YMOR"
        , "FAC_YMNY"
        , "FAC_YMTI"
        , "FAC_YMRY"
        , "FAC_YMBT"
        , "FAC_YMDY"
        , "FAC_YMCL"
        , "FAC_YMTG"
        , "FAC_YGON"
        , "FAC_YMHL"
        , "FAC_YHOT"
        , "FAC_YMHO"
        , "FAC_YMHW"
        , "FAC_YBMA"
        , "FAC_YMNE"
        , "FAC_YMOG"
        , "FAC_YMSF"
        , "FAC_YMOU"
        , "FAC_YMDG"
        , "FAC_YMWA"
        , "FAC_YMDA"
        , "FAC_YMGI"
        , "FAC_YLMU"
        , "FAC_YMRG"
        , "FAC_YMBD"
        , "FAC_YMUL"
        , "FAC_YMAE"
        , "FAC_YMMI"
        , "FAC_YMUR"
        , "FAC_YMTB"
        , "FAC_YMYU"
        , "FAC_YNKR"
        , "FAC_YNGW"
        , "FAC_YNAP"
        , "FAC_YNRC"
        , "FAC_YNRB"
        , "FAC_YNBR"
        , "FAC_YNAR"
        , "FAC_YNRG"
        , "FAC_YNRM"
        , "FAC_YNEY"
        , "FAC_YNRH"
        , "FAC_YNWN"
        , "FAC_YNGU"
        , "FAC_YNHL"
        , "FAC_YCNF"
        , "FAC_YNSH"
        , "FAC_YSNF"
        , "FAC_YNTN"
        , "FAC_YNSM"
        , "FAC_YNWF"
        , "FAC_YNTM"
        , "FAC_YNPE"
        , "FAC_YNOV"
        , "FAC_YSNW"
        , "FAC_YNUL"
        , "FAC_YNUB"
        , "FAC_YNUM"
        , "FAC_YNYN"
        , "FAC_YBOK"
        , "FAC_YOAY"
        , "FAC_YOCA"
        , "FAC_YOEN"
        , "FAC_YOLD"
        , "FAC_YOLW"
        , "FAC_YOOD"
        , "FAC_YORG"
        , "FAC_YOEH"
        , "FAC_YORB"
        , "FAC_YORR"
        , "FAC_YOSB"
        , "FAC_YPAC"
        , "FAC_YPAM"
        , "FAC_YPAY"
        , "FAC_YPBO"
        , "FAC_YPKS"
        , "FAC_YPEA"
        , "FAC_YPEF"
        , "FAC_PHAC"
        , "FAC_YPPH"
        , "FAC_YPJT"
        , "FAC_YPTB"
        , "FAC_YPBH"
        , "FAC_YPID"
        , "FAC_YPNN"
        , "FAC_YPWH"
        , "FAC_YPLU"
        , "FAC_YMPC"
        , "FAC_YPCE"
        , "FAC_YPOK"
        , "FAC_YPMP"
        , "FAC_YPAG"
        , "FAC_POCA"
        , "FAC_YPPD"
        , "FAC_YPKT"
        , "FAC_YPLC"
        , "FAC_YPMQ"
        , "FAC_YPIR"
        , "FAC_YPOD"
        , "FAC_YPMH"
        , "FAC_YBPN"
        , "FAC_YPKL"
        , "FAC_YPUG"
        , "FAC_YQNS"
        , "FAC_YQLP"
        , "FAC_YQDI"
        , "FAC_YQRN"
        , "FAC_YRNG"
        , "FAC_YNRV"
        , "FAC_YRYP"
        , "FAC_YRED"
        , "FAC_YREN"
        , "FAC_YSRI"
        , "FAC_YRMD"
        , "FAC_YRID"
        , "FAC_YRBE"
        , "FAC_YRBK"
        , "FAC_YROB"
        , "FAC_YROI"
        , "FAC_YBRK"
        , "FAC_YRLL"
        , "FAC_YROM"
        , "FAC_YRSY"
        , "FAC_YRAY"
        , "FAC_YRSB"
        , "FAC_YRSH"
        , "FAC_YRTI"
        , "FAC_YRNS"
        , "FAC_YRPA"
        , "FAC_YRTP"
        , "FAC_YRYL"
        , "FAC_YSII"
        , "FAC_YSTA"
        , "FAC_YSGE"
        , "FAC_YSTH"
        , "FAC_YSAM"
        , "FAC_YBSG"
        , "FAC_YSCO"
        , "FAC_YSCA"
        , "FAC_YSLK"
        , "FAC_YSEN"
        , "FAC_YSHK"
        , "FAC_YSHG"
        , "FAC_YSHT"
        , "FAC_YSHR"
        , "FAC_YSGT"
        , "FAC_YSMI"
        , "FAC_YSNB"
        , "FAC_YSOL"
        , "FAC_YSMB"
        , "FAC_YSGW"
        , "FAC_YGBI"
        , "FAC_YSGR"
        , "FAC_YSCR"
        , "FAC_YSPT"
        , "FAC_YSPK"
        , "FAC_YSPI"
        , "FAC_YSPE"
        , "FAC_YSWL"
        , "FAC_YSFG"
        , "FAC_YSTO"
        , "FAC_YSRN"
        , "FAC_YKBY"
        , "FAC_YSNY"
        , "FAC_YSRD"
        , "FAC_YBSU"
        , "FAC_YSRT"
        , "FAC_YSWB"
        , "FAC_YSWH"
        , "FAC_YSSY"
        , "FAC_YSBK"
        , "FAC_YTMB"
        , "FAC_YSTW"
        , "FAC_YTMN"
        , "FAC_YTAA"
        , "FAC_YTRE"
        , "FAC_YTAM"
        , "FAC_YTEF"
        , "FAC_YTEM"
        , "FAC_YTNK"
        , "FAC_YTNG"
        , "FAC_YTGM"
        , "FAC_YTGT"
        , "FAC_YLKS"
        , "FAC_YTMO"
        , "FAC_YVAL"
        , "FAC_YTDR"
        , "FAC_YTHY"
        , "FAC_YTIB"
        , "FAC_YTLP"
        , "FAC_YTBR"
        , "FAC_YPTN"
        , "FAC_YTOC"
        , "FAC_YTDN"
        , "FAC_YTKS"
        , "FAC_YTWN"
        , "FAC_YTWB"
        , "FAC_YTQY"
        , "FAC_YTOT"
        , "FAC_YBTL"
        , "FAC_YTEE"
        , "FAC_YTRA"
        , "FAC_YTTI"
        , "FAC_YTFA"
        , "FAC_YTST"
        , "FAC_YTUY"
        , "FAC_YTBB"
        , "FAC_YTMU"
        , "FAC_YTPK"
        , "FAC_YTYA"
        , "FAC_YTYH"
        , "FAC_YUDA"
        , "FAC_YUDG"
        , "FAC_YVRS"
        , "FAC_YVRD"
        , "FAC_YSWG"
        , "FAC_YWHG"
        , "FAC_YWKI"
        , "FAC_YWCH"
        , "FAC_YWLG"
        , "FAC_YWAG"
        , "FAC_YWGT"
        , "FAC_YWBR"
        , "FAC_YWRL"
        , "FAC_YWKW"
        , "FAC_YWVA"
        , "FAC_YWBS"
        , "FAC_YWBI"
        , "FAC_YWKB"
        , "FAC_YWRN"
        , "FAC_YWBL"
        , "FAC_YWCK"
        , "FAC_YWTL"
        , "FAC_YWTB"
        , "FAC_YWSG"
        , "FAC_YWAV"
        , "FAC_YWBN"
        , "FAC_YBWP"
        , "FAC_YWEL"
        , "FAC_YWTO"
        , "FAC_YANG"
        , "FAC_WMD"
        , "FAC_YWSL"
        , "FAC_YWWL"
        , "FAC_YWST"
        , "FAC_YWHC"
        , "FAC_YWHA"
        , "FAC_YWCA"
        , "FAC_YWMC"
        , "FAC_YWIS"
        , "FAC_YWLM"
        , "FAC_YWLU"
        , "FAC_YWDG"
        , "FAC_YWDH"
        , "FAC_YWTN"
        , "FAC_YWVR"
        , "FAC_YWOL"
        , "FAC_YWHP"
        , "FAC_YWND"
        , "FAC_YWDL"
        , "FAC_YWWI"
        , "FAC_YPWR"
        , "FAC_YWMP"
        , "FAC_YWUD"
        , "FAC_YWYA"
        , "FAC_YWYF"
        , "FAC_YWYM"
        , "FAC_YWYY"
        , "FAC_YWYR"
        , "FAC_YYMI"
        , "FAC_YYBK"
        , "FAC_YYRM"
        , "FAC_YYWG"
        , "FAC_YYKI"
        , "FAC_YYNG"
        , "FAC_YYND"
        ]
      ersards =
        [
          "RDS_YPAD"
        , "RDS_YPPF"
        , "RDS_YABA"
        , "RDS_YMAY"
        , "RDS_YBAS"
        , "RDS_YAPH"
        , "RDS_YAMB"
        , "RDS_YARA"
        , "RDS_YARG"
        , "RDS_YARM"
        , "RDS_YAUR"
        , "RDS_YMAV"
        , "RDS_YAYE"
        , "RDS_YBNS"
        , "RDS_YBGO"
        , "RDS_YBLT"
        , "RDS_YLLE"
        , "RDS_YBNA"
        , "RDS_YBRN"
        , "RDS_YBAR"
        , "RDS_YBRY"
        , "RDS_YBWX"
        , "RDS_YBTH"
        , "RDS_YBTI"
        , "RDS_YBIE"
        , "RDS_YBLU"
        , "RDS_YBLA"
        , "RDS_YBDG"
        , "RDS_YBIR"
        , "RDS_YBDV"
        , "RDS_YBCK"
        , "RDS_YBGD"
        , "RDS_YBOU"
        , "RDS_YBKE"
        , "RDS_YBWN"
        , "RDS_YBRW"
        , "RDS_YBWW"
        , "RDS_YBBN"
        , "RDS_YBAF"
        , "RDS_YBHI"
        , "RDS_YBRM"
        , "RDS_YBUN"
        , "RDS_YBUD"
        , "RDS_YBKT"
        , "RDS_YBLN"
        , "RDS_YBCS"
        , "RDS_YSCN"
        , "RDS_YCMW"
        , "RDS_YSCB"
        , "RDS_YCAR"
        , "RDS_YCDU"
        , "RDS_YCNY"
        , "RDS_YCNK"
        , "RDS_YBCV"
        , "RDS_YCHT"
        , "RDS_YCGO"
        , "RDS_YCCA"
        , "RDS_YCHK"
        , "RDS_YPXM"
        , "RDS_YCMT"
        , "RDS_YCEE"
        , "RDS_YCCY"
        , "RDS_YCBA"
        , "RDS_YPCC"
        , "RDS_YCOE"
        , "RDS_YCFS"
        , "RDS_YCDO"
        , "RDS_YCBP"
        , "RDS_YCKN"
        , "RDS_YCAH"
        , "RDS_YCOM"
        , "RDS_YCBB"
        , "RDS_YCNM"
        , "RDS_YCWA"
        , "RDS_YCTM"
        , "RDS_YCOR"
        , "RDS_YCRG"
        , "RDS_YCWR"
        , "RDS_YCKI"
        , "RDS_YCUN"
        , "RDS_YCMU"
        , "RDS_YCIN"
        , "RDS_YDLO"
        , "RDS_YPDN"
        , "RDS_YDGU"
        , "RDS_YDLQ"
        , "RDS_YDBY"
        , "RDS_YDPO"
        , "RDS_YDBI"
        , "RDS_YDOD"
        , "RDS_YDMG"
        , "RDS_YSDU"
        , "RDS_YDKG"
        , "RDS_YEJI"
        , "RDS_YMES"
        , "RDS_YECH"
        , "RDS_YPED"
        , "RDS_YELD"
        , "RDS_YEML"
        , "RDS_YESP"
        , "RDS_YFTZ"
        , "RDS_YFLI"
        , "RDS_YFBS"
        , "RDS_YFRT"
        , "RDS_YFTA"
        , "RDS_YFDF"
        , "RDS_YGPT"
        , "RDS_YGAY"
        , "RDS_YGTN"
        , "RDS_YGEL"
        , "RDS_YGIA"
        , "RDS_YGIG"
        , "RDS_YGLA"
        , "RDS_YGLI"
        , "RDS_YBCG"
        , "RDS_YGGE"
        , "RDS_YGDA"
        , "RDS_YGDI"
        , "RDS_YGLB"
        , "RDS_YPGV"
        , "RDS_YGFN"
        , "RDS_YGRS"
        , "RDS_YGTH"
        , "RDS_YGTE"
        , "RDS_YGDH"
        , "RDS_YHLC"
        , "RDS_YHML"
        , "RDS_YBHM"
        , "RDS_YHAY"
        , "RDS_YHBA"
        , "RDS_YMHB"
        , "RDS_YHPN"
        , "RDS_YHID"
        , "RDS_YHSM"
        , "RDS_YHUG"
        , "RDS_YIFL"
        , "RDS_YIVL"
        , "RDS_YJAB"
        , "RDS_YJAC"
        , "RDS_YJLC"
        , "RDS_YJUN"
        , "RDS_YKBR"
        , "RDS_YPKG"
        , "RDS_YKKG"
        , "RDS_YKAL"
        , "RDS_YKAR"
        , "RDS_YPKA"
        , "RDS_YKMB"
        , "RDS_YKNG"
        , "RDS_YKMP"
        , "RDS_YKER"
        , "RDS_YIMB"
        , "RDS_YKII"
        , "RDS_YKRY"
        , "RDS_YKSC"
        , "RDS_YKOW"
        , "RDS_YPKU"
        , "RDS_YLCG"
        , "RDS_YLEV"
        , "RDS_YLTV"
        , "RDS_YMLT"
        , "RDS_YLTN"
        , "RDS_YPLM"
        , "RDS_YLEC"
        , "RDS_YLST"
        , "RDS_YLEO"
        , "RDS_YLRD"
        , "RDS_YLIS"
        , "RDS_YLHR"
        , "RDS_YLRE"
        , "RDS_YLHI"
        , "RDS_YLOX"
        , "RDS_YBMK"
        , "RDS_YMND"
        , "RDS_YMCO"
        , "RDS_YMNG"
        , "RDS_YMGD"
        , "RDS_YMJM"
        , "RDS_YMBA"
        , "RDS_YMYB"
        , "RDS_YMBU"
        , "RDS_YMHU"
        , "RDS_YMEK"
        , "RDS_YMML"
        , "RDS_YMEN"
        , "RDS_YMMB"
        , "RDS_YMER"
        , "RDS_YMMU"
        , "RDS_YMIA"
        , "RDS_YMLS"
        , "RDS_YMGB"
        , "RDS_YOOM"
        , "RDS_YMRB"
        , "RDS_YMRW"
        , "RDS_YMOR"
        , "RDS_YMTI"
        , "RDS_YMRY"
        , "RDS_YMTG"
        , "RDS_YGON"
        , "RDS_YHOT"
        , "RDS_YBMA"
        , "RDS_YMNE"
        , "RDS_YMOG"
        , "RDS_YMDG"
        , "RDS_YMUL"
        , "RDS_YMMI"
        , "RDS_YNRC"
        , "RDS_YNBR"
        , "RDS_YNAR"
        , "RDS_YNRM"
        , "RDS_YNWN"
        , "RDS_YNGU"
        , "RDS_YNHL"
        , "RDS_YCNF"
        , "RDS_YSNF"
        , "RDS_YNTN"
        , "RDS_YNSM"
        , "RDS_YNPE"
        , "RDS_YNOV"
        , "RDS_YSNW"
        , "RDS_YNUM"
        , "RDS_YNYN"
        , "RDS_YBOK"
        , "RDS_YOEN"
        , "RDS_YOLD"
        , "RDS_YOLW"
        , "RDS_YORG"
        , "RDS_YORB"
        , "RDS_YOSB"
        , "RDS_YPAM"
        , "RDS_YPBO"
        , "RDS_YPKS"
        , "RDS_YPEA"
        , "RDS_YPPH"
        , "RDS_YPJT"
        , "RDS_YPLU"
        , "RDS_YMPC"
        , "RDS_YPCE"
        , "RDS_YPMP"
        , "RDS_YPAG"
        , "RDS_YPPD"
        , "RDS_YPKT"
        , "RDS_YPLC"
        , "RDS_YPMQ"
        , "RDS_YPIR"
        , "RDS_YPOD"
        , "RDS_YPMH"
        , "RDS_YBPN"
        , "RDS_YQLP"
        , "RDS_YQDI"
        , "RDS_YRNG"
        , "RDS_YNRV"
        , "RDS_YREN"
        , "RDS_YSRI"
        , "RDS_YRMD"
        , "RDS_YROI"
        , "RDS_YBRK"
        , "RDS_YROM"
        , "RDS_YRTI"
        , "RDS_YSII"
        , "RDS_YSTA"
        , "RDS_YSGE"
        , "RDS_YSTH"
        , "RDS_YBSG"
        , "RDS_YSCO"
        , "RDS_YSLK"
        , "RDS_YSHK"
        , "RDS_YSHT"
        , "RDS_YSNB"
        , "RDS_YSOL"
        , "RDS_YGBI"
        , "RDS_YSCR"
        , "RDS_YSPT"
        , "RDS_YSPE"
        , "RDS_YSWL"
        , "RDS_YSRN"
        , "RDS_YKBY"
        , "RDS_YSRD"
        , "RDS_YBSU"
        , "RDS_YSWH"
        , "RDS_YSSY"
        , "RDS_YSBK"
        , "RDS_YSTW"
        , "RDS_YTRE"
        , "RDS_YTAM"
        , "RDS_YTEF"
        , "RDS_YTEM"
        , "RDS_YTNK"
        , "RDS_YTNG"
        , "RDS_YTGM"
        , "RDS_YTGT"
        , "RDS_YTMO"
        , "RDS_YTIB"
        , "RDS_YPTN"
        , "RDS_YTOC"
        , "RDS_YTWB"
        , "RDS_YBTL"
        , "RDS_YTEE"
        , "RDS_YTRA"
        , "RDS_YTTI"
        , "RDS_YTST"
        , "RDS_YTBB"
        , "RDS_YTMU"
        , "RDS_YSWG"
        , "RDS_YWKI"
        , "RDS_YWLG"
        , "RDS_YWGT"
        , "RDS_YWBR"
        , "RDS_YWKB"
        , "RDS_YWRN"
        , "RDS_YWBL"
        , "RDS_YWCK"
        , "RDS_YBWP"
        , "RDS_YWTO"
        , "RDS_YANG"
        , "RDS_YWSL"
        , "RDS_YWWL"
        , "RDS_YWHA"
        , "RDS_YWLM"
        , "RDS_YWLU"
        , "RDS_YWDG"
        , "RDS_YWDH"
        , "RDS_YWTN"
        , "RDS_YWOL"
        , "RDS_YPWR"
        , "RDS_YWUD"
        , "RDS_YWYF"
        , "RDS_YWYM"
        , "RDS_YWYY"
        , "RDS_YYRM"
        , "RDS_YYWG"
        , "RDS_YYKI"
        , "RDS_YYNG"
        ]
      allersa =
        (ersaprelim ++ ersafac ++ ersards) >>= \f -> 
        ["current", "pending"] >>= \q ->
        ersas >>= \(Ersa _ d) ->
        let req = concat [q, "/ersa/", f, "_", uriAipDate d, ".pdf"]
        in pure (AipDocument (aipRequestGet req "") (dir </> req))
      allSimpleAipDocuments =
        simpleAipDocuments >>= \x -> 
        ["current", "pending"] >>= \q ->
        let req = concat [q, "/", x]
        in  pure (AipDocument (aipRequestGet req "") (dir </> req))
  in  AipDocuments
        (allSimpleAipDocuments ++ allersa)
