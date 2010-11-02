{-# LANGUAGE RecordWildCards #-}
module Recipe.Hackage(package, platform, hackage) where

import Recipe.Type
import General.Code


package :: RecipeDetails -> String -> IO ()
package RecipeDetails{..} _ = do
    download "-hackage.web" "http://hackage.haskell.org/cgi-bin/hackage-scripts/search"
    pkgs <- readHackage
    par $ flip map pkgs $ \(name,ver) -> do
        let url = "http://hackage.haskell.org/packages/archive/" ++ name ++ "/" ++ ver
            had = name ++ "-" ++ ver ++ "-haddock.web"
            cab = name ++ "-" ++ ver ++ "-cabal.web"
        b <- tryDownload had $ url ++ "/doc/html/" ++ name ++ ".txt"
        if not b then putStrLn $ "Warning: Could not download Hackage database for " ++ name else do
            download cab $ url ++ "/" ++ name ++ ".cabal"
            process [cab,had] [name ++ ".txt"] $ packageTextbase (name,ver)


packageTextbase :: (String,String) -> IO ()
packageTextbase (name,ver) = copyFile (name ++ "-" ++ ver ++ "-haddock.web") (name ++ ".txt")



hackage :: RecipeDetails -> String -> IO ()
hackage RecipeDetails{..} _ = do
    pkgs <- readHackage
    combine "hackage.hoo" [a <.> "hoo" | (a,b) <- pkgs]


readHackage :: IO [(String,String)]
readHackage = do
    src <- readFile "-hackage.web"
    let pre = "><a href=\"/package/"
    return $ map (second (drop 1) . rbreak (== '-') . init . drop (length pre)) $
            filter (isPrefixOf pre) $ map trim $ lines src


platform :: RecipeDetails -> String -> IO ()
platform RecipeDetails{..} _ = do
    download "-platform.web" "http://code.haskell.org/haskell-platform/haskell-platform.cabal"
    pkgs <- readPlatform
    combine "platform.hoo" [a <.> "hoo" | (a,b) <- pkgs]


readPlatform :: IO [(String,String)]
readPlatform = do
    src <- readFile "-platform.web"
    let xs = takeWhile (not . isPrefixOf "build-tools:" . ltrim) $
             dropWhile (not . isPrefixOf "build-depends:" . ltrim) $
             lines src
    return [(name, takeWhile (\x -> x == '.' || isDigit x) $ drop 1 b)
           | x <- xs, (a,_:b) <- [break (== '=') x], let name = trim $ dropWhile (== '-') $ trim a
           , name `notElem` words "Cabal hpc Win32"]
