-- 사용자 일괄 삭제 스크립트 (Update: v4 - With Saved Games)
-- Supabase SQL Editor에서 실행하세요.
-- 주의: 이 작업은 되돌릴 수 없습니다!

DO $$
DECLARE
    -- 삭제할 이메일들을 아래 배열 안에 쉼표(,)로 구분하여 입력하세요.
    target_emails TEXT[] := ARRAY[
        'cammupco@gmail.com', 
        'e3im0111@gmail.com', 
        'heartan32@gmail.com', 
        'waterlooamj@gmail.com'
    ];
    
    current_email TEXT;
    target_user_id UUID;
BEGIN
    -- 각 이메일에 대해 반복 수행
    FOREACH current_email IN ARRAY target_emails
    LOOP
        -- 변수 초기화
        target_user_id := NULL;
        
        -- 1. 이메일로 User ID 찾기
        SELECT id INTO target_user_id FROM auth.users WHERE email = current_email;

        IF target_user_id IS NULL THEN
            RAISE NOTICE 'Skipping: User not found (%)', current_email;
        ELSE
            RAISE NOTICE 'Processing: % (ID: %)', current_email, target_user_id;

            -- 2. 게임 세션 (game_sessions) 삭제
            DELETE FROM public.game_sessions WHERE mp_id = target_user_id;
            
            BEGIN
                DELETE FROM public.game_sessions WHERE cp_id = target_user_id;
            EXCEPTION WHEN OTHERS THEN
                -- 무시
            END;

            -- 3. 저장된 게임 (saved_games) 삭제 <--- 새로 추가된 부분
            -- 에러 메시지의 saved_games_user_id_fkey 로 보아 컬럼명은 user_id 입니다.
            DELETE FROM public.saved_games WHERE user_id = target_user_id;

            -- 4. 프로필 (profiles) 삭제
            DELETE FROM public.profiles WHERE id = target_user_id;

            -- 5. auth.users 테이블에서 사용자 삭제
            DELETE FROM auth.users WHERE id = target_user_id;
            
            RAISE NOTICE 'Deleted: %', current_email;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Batch deletion completed.';
END $$;
