class AudioFeaturesWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: :slow

  def perform(track_ids)
    tracks = Track.where(spotify_id: track_ids).where(audio_features: {}).where('audio_features_last_checked < ? OR audio_features_last_checked IS NULL', 72.hours.ago)
    tracks_with_spotify_ids = tracks.pluck(:spotify_id)

    spotify_tracks = RSpotify::AudioFeatures.find(tracks_with_spotify_ids)
    
    spotify_tracks.each do |spotify_track|
      if spotify_track.present?
        track = tracks.find{|a| a.spotify_id == spotify_track.id}
        track.update_attributes(audio_features: {
          acousticness: spotify_track.acousticness,
          danceability: spotify_track.danceability,
          energy: spotify_track.energy,
          instrumentalness: spotify_track.instrumentalness,
          key: spotify_track.key,
          liveness: spotify_track.liveness,
          loudness: spotify_track.loudness,
          mode: spotify_track.mode,
          speechiness: spotify_track.speechiness,
          tempo: spotify_track.tempo,
          time_signature: spotify_track.time_signature,
          valence: spotify_track.valence
        })
      end
    end
    
  end
end
