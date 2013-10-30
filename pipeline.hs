{-# LANGUAGE RecordWildCards #-}
module Pipeline 
	( run_pipeline )
where

	-- Modules
import Document.Document

import Serialize

import UnitB.AST
import UnitB.PO

import Z3.Z3 
		( discharge
		, Sequent
		, Validity ( .. ) )

	-- Libraries
import Control.Concurrent
import Control.Concurrent.STM.TChan

import Control.Monad
import Control.Monad.IO.Class
import Control.Monad.STM
import Control.Monad.Trans.State

import			 Data.Char
import			 Data.Map as M 
					( Map, empty, keysSet
					, insert, filterWithKey, keys
					, mapWithKey, lookup, fromList
					, toList, unions )
import qualified Data.Map as M 
					( map )
import			 Data.Maybe
import			 Data.Set as S 
					( Set, member, empty )

import System.Directory
import System.Console.ANSI

import Utilities.Format
import Utilities.Syntactic

	-- The pipeline is made of three processes:
	--	o the parser
	--  o the prover
	--  o the display
	--
	-- The prover and the parser _share_ a map of proof obligations
	-- The prover and the parser _share_ a list of PO labels
	-- The 
	
wait :: Monad m => m Bool -> m ()
wait m = do
		b <- m
		if b 
			then return ()
			else wait m
			
data Shared = Shared
		{ pos     :: MVar (Map (Label,Label) Seq)
		, tok     :: MVar ()
		, lbls    :: MVar (Either [Error] (Set (Label,Label)))
		, status  :: TChan (Label,Label,Seq,Bool)
		, working :: MVar Int
		, ser     :: MVar ((Map (Label,Label) (Seq,Bool), Set (Label,Label)),[Error])
		, fname   :: FilePath
		-- , io      :: MVar String
		}
			
data Display = Display
		{ result :: Map (Label,Label) (Seq,Bool)
		, labels :: Set (Label,Label)
		, errors :: [Error]
		}

--console io = forever $ do
--	xs <- takeMVar io
--	putStrLn xs
			
parser :: Shared
	   -> IO ()
parser (Shared { .. })  = do
		t <- getModificationTime fname
		parse
		evalStateT (forever $ do
			liftIO $ threadDelay 1000000
			t0 <- get
			t1 <- liftIO $ getModificationTime fname
			if t0 == t1 then return ()
			else do
				put t1
				liftIO $ parse
			) t
	where
		f m = do
			x <- proof_obligation m
			return $ fromList $ map (g $ _name m) $ toList $ x
		g lbl (x,y) = ((lbl,x),y)
		parse = do
				ms <- parse_machine fname
				let xs = ms >>= mapM f :: Either [Error] [Map (Label,Label) Sequent]
				case xs of
					Right ms -> do
						let pos_list = unions ms
						swapMVar pos pos_list
						tryTakeMVar lbls
						putMVar lbls (Right $ keysSet pos_list)
						tryPutMVar tok ()
						return ()
					Left es   -> do
						tryTakeMVar lbls
						putMVar lbls (Left es)
						return ()

prover :: Shared
	   -> StateT (Map (Label,Label) (Seq,Bool)) IO ()
prover (Shared { .. }) = do
	req <- liftIO $ do
		req <- newEmptyMVar
		forM_ [1..8] $ \p -> forkOn p $ worker req 
		return req
	forever $ do
		liftIO $ do
			takeMVar tok
			inc 200
		po <- liftIO $ readMVar pos
		renew po
		po <- get
		forM_ (keys po) $ \k -> do
			po <- gets $ M.lookup k
			case po of
				Just (po,True) -> do
					liftIO $ putMVar req (k,po)
					modify $ insert k (po,False)
				_			   -> return ()
			update_state
		liftIO $ dec 200
	where
		update_state = do
			b <- liftIO $ isEmptyMVar tok
			if b then return ()
			else do
				po <- liftIO $ readMVar pos
				renew po
				return ()
		renew :: Map (Label,Label) Seq
			  -> StateT (Map (Label,Label) (Seq,Bool)) IO ()
		renew pos = do
			st <- get
			put $ M.mapWithKey (f st) pos
		f st k v = case M.lookup k st of
			Just (po,r)
				| v == po && not r -> (po,False)
				| otherwise        -> (v, True)
			Nothing -> (v,True)
		inc x = modifyMVar_ working (return . (+x))
		dec x = modifyMVar_ working (return . (+ (-x)))			
		worker req = forever $ do
			(k,po) <- takeMVar req
			inc 1
			r      <- discharge po
			dec 1
			atomically $ writeTChan status (fst k,snd k,po,r == Valid)

proof_report outs es b = xs ++ 
					 ( if null es then []
					   else "> errors" : map report es ) ++
					 [ if b
					   then "> working ..."
					   else ""
					 ] 
	where
		xs = concatMap f (toList outs)
		f ((m,lbl),(_,r))
			| not r   	= [format " x {0} - {1}" m lbl]
			| otherwise = []
			
display :: Shared
	    -> StateT Display IO ()
display (Shared { .. }) = do
	liftIO $ clearScreen
	forever $ do
		do	outs <- gets result
			lbls <- gets labels
			es   <- gets errors
			liftIO $ do
				tryTakeMVar ser
				putMVar ser ((outs,lbls),es)
				-- xs <- forM (toList outs) $ \((m,lbl),(_,r)) -> do
					-- if not r then
						-- liftIO $ putMVar io $ format "{0}{1} - {2}" x m lbl
						-- return [format " x {0} - {1}" m lbl]
					-- else return []
				b1 <- readMVar working
				b2 <- atomically $ isEmptyTChan status
				let ys = proof_report outs es (b1 /= 0 || not b2)
				cursorUpLine $ length ys
				clearFromCursorToScreenBeginning
				forM_ ys $ \x -> do
					-- clearLine
					putStr x
					clearFromCursorToLineEnd 
					putStrLn ""
				putStrLn $ format "n workers: {0}  Channel: {1}" b1 (if b2 then "empty" else "non-empty")
		wait $ do
			liftIO $ threadDelay 500000
			st <- take_n 10
			ls <- liftIO $ tryTakeMVar lbls
			case ls of
				Just (Right ls) -> do 
					let f k _ = k `S.member` ls
					modify $ \d -> d
						{ result = M.filterWithKey f $ result d 
						, labels = ls
						, errors = [] }
				Just (Left es) ->
					modify $ \d -> d
						{ errors = es }
				Nothing -> return ()
			lbls <- gets labels
			forM_ st $ \(m,lbl,r,s) -> do
				if (m,lbl) `S.member` lbls then
					modify $ \d -> d 
						{ result = insert (m,lbl) (r,s) $ result d }
				else return ()
			return $ not (null st && isNothing ls)
	where
		take_n 0 = return []
		take_n n = do
			b <- liftIO $ atomically $ isEmptyTChan status
			if b then
				return []
			else do
				x  <- liftIO $ atomically $ readTChan status
				xs <- take_n (n-1)
				return (x:xs)

serialize (Shared { .. }) = forever $ do
		threadDelay 10000000
		(pos@(out,_),es) <- takeMVar ser
		dump_pos fname pos
		dump_z3 fname pos
		writeFile (fname ++ ".report") (unlines $ proof_report out es False)
				
keyboard = do
		xs <- getLine
		if map toLower xs == "quit" 
			then return ()
			else do
				putStrLn $ format "Invalid command: '{0}'" xs
				keyboard
				
run_pipeline fname = do
		pos     <- newMVar M.empty
		lbls    <- newEmptyMVar
		tok     <- newEmptyMVar
		ser     <- newEmptyMVar
		status  <- newTChanIO
		-- io      <- newEmptyMVar
		working <- newMVar 0
		let sh = Shared { .. }
		(m,s) <- load_pos fname (M.empty,S.empty)
		t0 <- forkIO $ evalStateT (display sh) (Display m s [])
		t1 <- forkIO $ evalStateT (prover sh) (M.map f m)
		-- t2 <- forkIO $ console io
		t2 <- forkIO $ serialize sh
		t3 <- forkIO $ parser sh
		keyboard 
		putStrLn "received a 'quit' command"
		killThread t0
		killThread t1
		killThread t2
		killThread t3
	where
		f (x,_) = (x,False)