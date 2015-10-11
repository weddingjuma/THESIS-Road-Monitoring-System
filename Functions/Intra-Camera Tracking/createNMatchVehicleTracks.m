function [vehicleTracks, nextId, tracksToMatch] = createNewVehicleTracks(vehicleTracks, vehicleClassifier, tracksToMatch, nextId, unassignedDetections, frame, centroids, bboxes, kConfig, location, time, outputHandler)
	centroids = centroids(unassignedDetections, :);
	bboxes = bboxes(unassignedDetections, :);
	
	for i = 1:size(centroids, 1)
		centroid = centroids(i, :);
		bbox = bboxes(i, :);
		
		kalman = configureKalmanFilter(...
			kConfig.MotionModel, ...
			centroid, ...
			kConfig.Error, ...
			kConfig.MotionNoise, ...
			kConfig.MeasurementNoise ...
			);
		
		image = imcrop(frame, bbox);
		features = extractColorFeatures(image);

		[class, vehicleType, len, width] = determineTypeAndSize(vehicleClassifier, image);
		dimensions = [len width];

		id = nextId;
		index = matchTracks(tracksToMatch, class, vehicleType, dimensions, features, 0.9);

		if strcmp(class,'NA')
		else
			if ~isempty(index)
				id = tracksToMatch(index).id;
				tracksToMatch(index) = [];
			end
			vehicleTrack = struct(...
				'id', 	id, ...
				'bbox', bbox, ...
				'kalman', kalman, ...
				'age', 1, ...
				'image', image, ...
				'visibleCount', 1, ...
				'invisibleCount', 0, ...
				'features', features, ...
				'class', class, ...
				'type', vehicleType, ...
				'dimensions', dimensions ...
				);

			outputTrack(outputHandler.track, location, time, class, vehicleType, len, width, nextId);
			outputTrack2(outputHandler.track2, location, time, class, vehicleType, len, width, nextId, 'ENTER');

			vehicleTracks(end + 1) = vehicleTrack;
			nextId = nextId + 1*(isempty(index));
		end
	end
end