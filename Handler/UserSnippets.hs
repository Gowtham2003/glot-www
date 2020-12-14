module Handler.UserSnippets where

import Import
import Model.Snippet.Api (listSnippets, listSnippetsByOwner, listSnippetsByLanguage, listSnippetsByOwnerByLanguage)
import Util.Handler (maybeApiUser, pageNo, titleConcat, apiRequestHeaders)
import Util.Snippet (visibilityFormat)
import Widget.Pagination (paginationWidget)

getUserSnippetsR :: Text -> Handler Html
getUserSnippetsR username = do
    Entity _ profile <- runDB $ getBy404 $ UniqueUsername username
    mAuthUserId <- maybeAuthId
    currentPage <- pageNo <$> lookupGetParam "page"
    mLanguage <- lookupGetParam "language"
    (snippets, pagination) <- fetchSnippets mAuthUserId (profileUserId profile) mLanguage currentPage
    defaultLayout $ do
        setTitle $ titleConcat ["Snippets by ", profileName profile]
        addScript $ StaticR js_date_js
        $(widgetFile "user-snippets")

fetchSnippets :: Maybe UserId -> UserId -> Maybe Text -> Int -> Handler ([MetaSnippet], Pagination)
-- Fetch own snippets by language
fetchSnippets (Just authUserId) userId (Just lang) page
    | userId == authUserId = do
        mApiUser <- maybeApiUser $ Just authUserId
        req <- reqWaiRequest <$> getRequest
        let authToken = apiUserToken <$> mApiUser
        let headers = apiRequestHeaders req authToken
        liftIO $ listSnippetsByLanguage lang page headers
-- Fetch own snippets
fetchSnippets (Just authUserId) userId Nothing page
    | userId == authUserId = do
        mApiUser <- maybeApiUser $ Just authUserId
        req <- reqWaiRequest <$> getRequest
        let authToken = apiUserToken <$> mApiUser
        let headers = apiRequestHeaders req authToken
        liftIO $ listSnippets page headers
-- Fetch strangers's snippets by language
fetchSnippets _ userId (Just lang) page = do
    maybeUser <- maybeApiUser $ Just userId
    case maybeUser of
        Just apiUser -> do
            req <- reqWaiRequest <$> getRequest
            let headers = apiRequestHeaders req Nothing
            liftIO $ listSnippetsByOwnerByLanguage (apiUserSnippetsId apiUser) lang page headers

        Nothing ->
            error "Api user not found"
-- Fetch strangers's snippets
fetchSnippets _ userId Nothing page = do
    maybeUser <- maybeApiUser $ Just userId
    case maybeUser of
        Just apiUser -> do
            req <- reqWaiRequest <$> getRequest
            let headers = apiRequestHeaders req Nothing
            liftIO $ listSnippetsByOwner (apiUserSnippetsId apiUser) page headers

        Nothing ->
            error "Api user not found"
