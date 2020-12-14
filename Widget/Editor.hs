module Widget.Editor (
    editorWidget,
    footerWidget
) where

import Import
import Util.Handler (maybeApiUser)
import Util.Snippet (isSnippetOwner, visibilityFormat, formatRunParams)
import Model.Run.Api (listLanguageVersions)
import Widget.CarbonAds (carbonAdsWidget)
import Settings.Environment (disableAds)

listVersions :: Text -> IO [Text]
listVersions lang = do
    res <- safeListVersions lang
    return $ case res of
        Left _ -> []
        Right versions -> versions

safeListVersions :: Text -> IO (Either SomeException [Text])
safeListVersions lang = try $ listLanguageVersions lang


editorWidget :: Language -> Snippet -> Maybe (Entity Profile) -> Maybe (Entity RunParams) -> Widget
editorWidget lang snippet profile runParams = do
    addScript $ StaticR lib_ace_ace_js
    $(widgetFile "widgets/editor")
    where
        fileCount = length $ snippetFiles snippet

metaWidget :: Snippet -> Maybe (Entity Profile) -> Maybe (Entity RunParams) -> Widget
metaWidget snippet mProfile runParams = do
    mUserId <- handlerToWidget maybeAuthId
    mApiUser <- handlerToWidget $ maybeApiUser mUserId
    versions <- liftIO $ listVersions $ snippetLanguage snippet
    addScript $ StaticR js_date_js
    $(widgetFile "widgets/editor/meta")
    where
        (_, currentVersion, runCommand) = formatRunParams runParams
        lang = toLanguage $ snippetLanguage snippet

settingsWidget :: Widget
settingsWidget = $(widgetFile "widgets/editor/settings")

footerWidget :: Bool -> Bool -> Bool -> Maybe (Entity RunParams) -> Maybe (Entity RunResult) -> Widget
footerWidget isComposing isRunnable isOwner runParams runResult =
    let
        (stdinData, _, _) = formatRunParams runParams
        (stdoutRes, stderrRes, errorRes, hasRunResult) = formatRunResult runResult
    in do
        showAds <- liftIO $ not <$> disableAds
        $(widgetFile "widgets/editor/footer")

formatRunResult :: Maybe (Entity RunResult) -> (Text, Text, Text, Bool)
formatRunResult (Just (Entity _ res)) =
    let
        stdoutRes = runResultStdout res
        stderrRes = runResultStderr res
        errorRes = runResultError res
        hasRunResult = not $ all null [stdoutRes, stderrRes, errorRes]
    in
        (stdoutRes, stderrRes, errorRes, hasRunResult)
formatRunResult _ =
    ("", "", "", False)


maxFiles :: Int
maxFiles = 6

enumerateFiles :: Snippet -> [(Int, Maybe SnippetFile)]
enumerateFiles s = zip [1..] $ ensureLength maxFiles $ snippetFiles s

ensureLength :: Int -> [SnippetFile] -> [Maybe SnippetFile]
ensureLength n files = take n $ map Just files ++ replicate n Nothing

getFileContent :: Maybe SnippetFile -> Text
getFileContent (Just f) = snippetFileContent f
getFileContent Nothing = ""

getFilename :: Language -> Maybe SnippetFile -> Int -> Text
getFilename _ (Just f) _ = snippetFileName f
getFilename lang Nothing 2 = addExt lang "dio"
getFilename lang Nothing 3 = addExt lang "tria"
getFilename lang Nothing 4 = addExt lang "tessera"
getFilename lang Nothing 5 = addExt lang "pente"
getFilename lang Nothing 6 = addExt lang "eksi"
getFilename lang Nothing 7 = addExt lang "efta"
getFilename lang Nothing 8 = addExt lang "okto"
getFilename lang Nothing 9 = addExt lang "enia"
getFilename lang Nothing _ = addExt lang "infinitum"

addExt :: Language -> Text -> Text
addExt lang name = concat [name, ".", languageFileExt lang]

isComposing :: Snippet -> Bool
isComposing s = null $ snippetId s
