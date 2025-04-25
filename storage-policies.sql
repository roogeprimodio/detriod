-- Update profile-images policies
ALTER POLICY "Public read access" ON storage.objects
USING (bucket_id = 'profile-images');

ALTER POLICY "Give anon users access to JPG images in folder vejz8c_1" ON storage.objects
USING (
  bucket_id = 'profile-images' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

ALTER POLICY "Give anon users access to JPG images in folder vejz8c_2" ON storage.objects
USING (
  bucket_id = 'profile-images' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

ALTER POLICY "Give anon users access to JPG images in folder vejz8c_3" ON storage.objects
USING (
  bucket_id = 'profile-images' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Update game-images policies
ALTER POLICY "Public read access" ON storage.objects
USING (bucket_id = 'game-images');

ALTER POLICY "Give anon users access to JPG images in folder 16wos6r_1" ON storage.objects
USING (
  bucket_id = 'game-images' AND 
  auth.role() = 'authenticated'
);

ALTER POLICY "Give anon users access to JPG images in folder 16wos6r_2" ON storage.objects
USING (
  bucket_id = 'game-images' AND 
  auth.role() = 'authenticated'
);

ALTER POLICY "Give anon users access to JPG images in folder 16wos6r_3" ON storage.objects
USING (
  bucket_id = 'game-images' AND 
  auth.role() = 'authenticated'
);

-- Update match-screenshots policies
ALTER POLICY "Public read access" ON storage.objects
USING (bucket_id = 'match-screenshots');

ALTER POLICY "Give anon users access to JPG images in folder 8j7q9x_0" ON storage.objects
USING (
  bucket_id = 'match-screenshots' AND 
  auth.role() = 'authenticated'
);

ALTER POLICY "Give anon users access to JPG images in folder 8j7q9x_2" ON storage.objects
USING (
  bucket_id = 'match-screenshots' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

ALTER POLICY "Give anon users access to JPG images in folder 8j7q9x_3" ON storage.objects
USING (
  bucket_id = 'match-screenshots' AND 
  auth.role() = 'authenticated' AND
  (storage.foldername(name))[1] = auth.uid()::text
); 