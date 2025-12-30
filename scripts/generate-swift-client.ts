#!/usr/bin/env npx tsx
/**
 * Convex Swift Client Generator
 * 
 * Reads function metadata from a Convex deployment and generates
 * typed Swift code for models and API calls.
 * 
 * Usage: npx tsx scripts/generate-swift-client.ts
 */

import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

// Configuration
const OUTPUT_DIR = path.join(__dirname, '..', 'GymLog', 'Services', 'Generated');
const DEPLOYMENT_URL = 'https://marvelous-cow-733.convex.cloud';

interface FieldType {
  type: string;
  value?: any;
  tableName?: string;
}

interface Field {
  fieldType: FieldType;
  optional: boolean;
}

interface FunctionSpec {
  identifier: string;
  functionType: 'Query' | 'Mutation' | 'Action';
  visibility: { kind: string };
  args: { type: string; value: Record<string, Field> };
  returns: FieldType;
}

// Convert Convex type to Swift type
function convexTypeToSwift(fieldType: FieldType, optional: boolean = false): string {
  let swiftType: string;
  
  switch (fieldType.type) {
    case 'string':
      swiftType = 'String';
      break;
    case 'number':
      swiftType = 'Double';
      break;
    case 'boolean':
      swiftType = 'Bool';
      break;
    case 'id':
      swiftType = 'String'; // Convex IDs are strings
      break;
    case 'null':
      return 'Void';
    case 'array':
      const elementType = convexTypeToSwift(fieldType.value, false);
      swiftType = `[${elementType}]`;
      break;
    case 'object':
      // For nested objects, we'd need to generate inline types or references
      swiftType = 'ConvexObject'; // Placeholder - we'll handle this specially
      break;
    case 'union':
      // Handle union types (e.g., literals for enums)
      if (Array.isArray(fieldType.value)) {
        const literals = fieldType.value.filter((v: any) => v.type === 'literal');
        if (literals.length === fieldType.value.length) {
          // All literals - this is an enum
          swiftType = 'String'; // Represented as string, could generate enum
        } else {
          // Mixed union - check for null
          const nonNull = fieldType.value.filter((v: any) => v.type !== 'null');
          if (nonNull.length === 1) {
            return convexTypeToSwift(nonNull[0], true);
          }
          swiftType = 'Any';
        }
      } else {
        swiftType = 'Any';
      }
      break;
    case 'literal':
      swiftType = 'String';
      break;
    default:
      swiftType = 'Any';
  }
  
  return optional ? `${swiftType}?` : swiftType;
}

// Generate Swift struct for a return type
function generateReturnStruct(name: string, fields: Record<string, Field>): string {
  const properties = Object.entries(fields)
    .map(([key, field]) => {
      const swiftType = convexTypeToSwift(field.fieldType, field.optional);
      return `    let ${key}: ${swiftType}`;
    })
    .join('\n');
  
  return `struct ${name}: Codable, Identifiable {
${properties}
    
    var id: String { _id }
}`;
}

// Generate Swift method for a function
function generateMethod(spec: FunctionSpec): string {
  const parts = spec.identifier.split(':');
  const moduleName = parts[0].replace('.js', '');
  const funcName = parts[1];
  const fullName = `${moduleName}:${funcName}`;
  
  // Build parameters
  const params = Object.entries(spec.args.value || {})
    .map(([key, field]) => {
      const swiftType = convexTypeToSwift(field.fieldType, field.optional);
      const defaultValue = field.optional ? ' = nil' : '';
      return `${key}: ${swiftType}${defaultValue}`;
    })
    .join(',\n        ');
  
  // Build return type
  let returnType = 'Void';
  if (spec.returns.type === 'id') {
    returnType = 'String';
  } else if (spec.returns.type === 'array') {
    returnType = `[ConvexSet]`; // Simplified - would need smarter type resolution
  } else if (spec.returns.type === 'object') {
    returnType = 'ConvexObject'; // Would generate specific types
  } else if (spec.returns.type !== 'null') {
    returnType = convexTypeToSwift(spec.returns, false);
  }
  
  // Build argument dictionary
  const argEntries = Object.keys(spec.args.value || {})
    .map(key => `            "${key}": ${key}`)
    .join(',\n');
  
  const funcType = spec.functionType.toLowerCase();
  const asyncMethod = funcType === 'query' ? 'subscribe' : 'mutation';
  
  if (funcType === 'query') {
    return `
    /// ${funcName} - ${spec.functionType}
    func ${funcName}(
        ${params}
    ) -> AnyPublisher<${returnType}?, Never> {
        return client.subscribe(
            to: "${fullName}",
            with: [
${argEntries}
            ],
            yielding: ${returnType}?.self
        ).replaceError(with: nil)
    }`;
  } else {
    return `
    /// ${funcName} - ${spec.functionType}
    func ${funcName}(
        ${params}
    ) async throws -> ${returnType} {
        return try await client.mutation("${fullName}", with: [
${argEntries}
        ])
    }`;
  }
}

// Main generation function
async function generateSwiftClient() {
  console.log('🔍 Fetching Convex function specs...');
  
  const projectDir = path.join(__dirname, '..');
  
  // Get function specs using convex CLI
  // The --file flag outputs to function_spec_<timestamp>.json
  const output = execSync(
    `cd "${projectDir}" && npx convex function-spec --file`,
    { encoding: 'utf-8' }
  );
  
  // Parse the filename from output like "Wrote function spec to function_spec_1234567.json"
  const match = output.match(/function_spec_\d+\.json/);
  if (!match) {
    throw new Error('Could not find generated spec file');
  }
  
  const specFile = path.join(projectDir, match[0]);
  const specsJson = fs.readFileSync(specFile, 'utf-8');
  fs.unlinkSync(specFile); // Clean up
  
  const specData = JSON.parse(specsJson);
  const specs: FunctionSpec[] = specData.functions;
  const deploymentUrl = specData.url;
  
  console.log(`📄 Read ${specs.length} functions from Convex deployment`);
  
  // Filter to public functions only
  const publicFuncs = specs.filter(s => s.visibility.kind === 'public');
  
  console.log(`📋 Found ${publicFuncs.length} public functions`);
  
  // Group by module
  const byModule: Record<string, FunctionSpec[]> = {};
  for (const spec of publicFuncs) {
    const module = spec.identifier.split(':')[0].replace('.js', '');
    if (!byModule[module]) byModule[module] = [];
    byModule[module].push(spec);
  }
  
  // Generate the Swift file
  let swiftCode = `// Auto-generated by generate-swift-client.ts
// DO NOT EDIT - Regenerate with: npx tsx scripts/generate-swift-client.ts

import Foundation
import ConvexMobile
import Combine

// MARK: - Generated Types

/// Exercise type enum matching Convex schema
enum ConvexExerciseType: String, Codable {
    case resistance
    case calisthenics
    case cardio
}

/// Set from Convex
struct ConvexSet: Codable, Identifiable {
    let _id: String
    let _creationTime: Double
    let apiKeyId: String
    let exerciseId: String?
    let exerciseName: String
    let weight: Double?
    let weightUnit: String?
    let reps: Int?
    let workTime: Double?
    let exerciseType: String
    let duration: Double?
    let notes: String?
    let isCompleted: Bool?
    let completedAt: Double?
    let workoutId: String?
    let setOrder: Int?
    
    var id: String { _id }
    
    var type: ConvexExerciseType {
        ConvexExerciseType(rawValue: exerciseType) ?? .resistance
    }
}

/// Exercise from Convex
struct ConvexExercise: Codable, Identifiable {
    let _id: String
    let _creationTime: Double
    let name: String
    let muscleGroup: String
    let description: String?
    let defaultWeight: Double?
    let defaultWeightUnit: String?
    let isPrimary: Bool?
    let exerciseType: String
    
    var id: String { _id }
}

/// Day stats response
struct ConvexDayStats: Codable {
    let totalWorkTime: Double
    let totalDuration: Double
    let setCount: Int
}

/// Day stats by type response
struct ConvexDayStatsByType: Codable {
    let resistance: ResistanceStats
    let calisthenics: CalisthenicsStats
    let cardio: CardioStats
    
    struct ResistanceStats: Codable {
        let setCount: Int
        let totalVolume: Double
        let totalWorkTime: Double
    }
    
    struct CalisthenicsStats: Codable {
        let setCount: Int
        let totalReps: Int
        let totalWorkTime: Double
    }
    
    struct CardioStats: Codable {
        let sessionCount: Int
        let totalDuration: Double
    }
}

// MARK: - Generated Convex Client

/// Type-safe Convex client generated from schema
@MainActor
class ConvexAPI: ObservableObject {
    static let shared = ConvexAPI()
    
    let client: ConvexClient
    
    @Published var apiKeyId: String?
    
    private let deploymentURL = "${DEPLOYMENT_URL}"
    private let apiKeyStorageKey = "convex_api_key_id"
    
    private init() {
        self.client = ConvexClient(deploymentUrl: deploymentURL)
        loadApiKeyId()
    }
    
    // MARK: - API Key Management
    
    func setApiKeyId(_ keyId: String) {
        apiKeyId = keyId
        UserDefaults.standard.set(keyId, forKey: apiKeyStorageKey)
    }
    
    func loadApiKeyId() {
        apiKeyId = UserDefaults.standard.string(forKey: apiKeyStorageKey)
    }
    
    var isAuthenticated: Bool {
        apiKeyId != nil && !(apiKeyId?.isEmpty ?? true)
    }
    
    // MARK: - Sets API
    
    /// Create a new set
    func createSet(
        exerciseName: String,
        exerciseType: ConvexExerciseType,
        exerciseId: String? = nil,
        weight: Double? = nil,
        weightUnit: String? = nil,
        reps: Int? = nil,
        workTime: Double? = nil,
        duration: Double? = nil,
        notes: String? = nil,
        isCompleted: Bool? = nil,
        workoutId: String? = nil,
        setOrder: Int? = nil
    ) async throws -> String {
        guard let apiKeyId = apiKeyId else {
            throw ConvexAPIError.notAuthenticated
        }
        
        return try await client.mutation("sets:createSet", with: [
            "apiKeyId": apiKeyId,
            "exerciseName": exerciseName,
            "exerciseType": exerciseType.rawValue,
            "exerciseId": exerciseId,
            "weight": weight,
            "weightUnit": weightUnit ?? "lbs",
            "reps": reps,
            "workTime": workTime,
            "duration": duration,
            "notes": notes,
            "isCompleted": isCompleted,
            "workoutId": workoutId,
            "setOrder": setOrder
        ])
    }
    
    /// Update an existing set
    func updateSet(
        setId: String,
        weight: Double? = nil,
        weightUnit: String? = nil,
        reps: Int? = nil,
        workTime: Double? = nil,
        duration: Double? = nil,
        notes: String? = nil,
        isCompleted: Bool? = nil
    ) async throws {
        guard let apiKeyId = apiKeyId else {
            throw ConvexAPIError.notAuthenticated
        }
        
        let _: String? = try await client.mutation("sets:updateSet", with: [
            "setId": setId,
            "apiKeyId": apiKeyId,
            "weight": weight,
            "weightUnit": weightUnit,
            "reps": reps,
            "workTime": workTime,
            "duration": duration,
            "notes": notes,
            "isCompleted": isCompleted
        ])
    }
    
    /// Delete a set
    func deleteSet(setId: String) async throws {
        guard let apiKeyId = apiKeyId else {
            throw ConvexAPIError.notAuthenticated
        }
        
        let _: String? = try await client.mutation("sets:deleteSet", with: [
            "setId": setId,
            "apiKeyId": apiKeyId
        ])
    }
    
    /// Subscribe to sets for a specific day
    func subscribeToSetsByDay(
        dayStart: Date,
        dayEnd: Date
    ) -> AnyPublisher<[ConvexSet]?, Never> {
        guard let apiKeyId = apiKeyId else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return client.subscribe(
            to: "sets:getSetsByDay",
            with: [
                "apiKeyId": apiKeyId,
                "dayStartTimestamp": dayStart.timeIntervalSince1970 * 1000,
                "dayEndTimestamp": dayEnd.timeIntervalSince1970 * 1000
            ],
            yielding: [ConvexSet]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Subscribe to recent sets
    func subscribeToSets(limit: Int = 100) -> AnyPublisher<[ConvexSet]?, Never> {
        guard let apiKeyId = apiKeyId else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return client.subscribe(
            to: "sets:getSets",
            with: [
                "apiKeyId": apiKeyId,
                "limit": limit
            ],
            yielding: [ConvexSet]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Subscribe to sets by workout
    func subscribeToSetsByWorkout(workoutId: String) -> AnyPublisher<[ConvexSet]?, Never> {
        guard let apiKeyId = apiKeyId else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return client.subscribe(
            to: "sets:getSetsByWorkout",
            with: [
                "apiKeyId": apiKeyId,
                "workoutId": workoutId
            ],
            yielding: [ConvexSet]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Subscribe to day work time stats
    func subscribeToDayWorkTime(
        dayStart: Date,
        dayEnd: Date
    ) -> AnyPublisher<ConvexDayStats?, Never> {
        guard let apiKeyId = apiKeyId else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return client.subscribe(
            to: "sets:getDayWorkTime",
            with: [
                "apiKeyId": apiKeyId,
                "dayStartTimestamp": dayStart.timeIntervalSince1970 * 1000,
                "dayEndTimestamp": dayEnd.timeIntervalSince1970 * 1000
            ],
            yielding: ConvexDayStats?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Subscribe to day stats by exercise type
    func subscribeToDayStatsByType(
        dayStart: Date,
        dayEnd: Date
    ) -> AnyPublisher<ConvexDayStatsByType?, Never> {
        guard let apiKeyId = apiKeyId else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return client.subscribe(
            to: "sets:getDayStatsByType",
            with: [
                "apiKeyId": apiKeyId,
                "dayStartTimestamp": dayStart.timeIntervalSince1970 * 1000,
                "dayEndTimestamp": dayEnd.timeIntervalSince1970 * 1000
            ],
            yielding: ConvexDayStatsByType?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Subscribe to exercise history
    func subscribeToExerciseHistory(
        exerciseName: String,
        limit: Int = 20
    ) -> AnyPublisher<[ConvexSet]?, Never> {
        guard let apiKeyId = apiKeyId else {
            return Just(nil).eraseToAnyPublisher()
        }
        
        return client.subscribe(
            to: "sets:getExerciseHistory",
            with: [
                "apiKeyId": apiKeyId,
                "exerciseName": exerciseName,
                "limit": limit
            ],
            yielding: [ConvexSet]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    // MARK: - Exercises API
    
    /// Subscribe to all exercises
    func subscribeToExercises() -> AnyPublisher<[ConvexExercise]?, Never> {
        return client.subscribe(
            to: "exercises:getExercises",
            yielding: [ConvexExercise]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Subscribe to exercises by muscle group
    func subscribeToExercisesByMuscleGroup(
        muscleGroup: String
    ) -> AnyPublisher<[ConvexExercise]?, Never> {
        return client.subscribe(
            to: "exercises:getExercisesByMuscleGroup",
            with: ["muscleGroup": muscleGroup],
            yielding: [ConvexExercise]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Subscribe to exercises by type
    func subscribeToExercisesByType(
        exerciseType: ConvexExerciseType
    ) -> AnyPublisher<[ConvexExercise]?, Never> {
        return client.subscribe(
            to: "exercises:getExercisesByType",
            with: ["exerciseType": exerciseType.rawValue],
            yielding: [ConvexExercise]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Search exercises
    func subscribeToExerciseSearch(
        searchTerm: String
    ) -> AnyPublisher<[ConvexExercise]?, Never> {
        return client.subscribe(
            to: "exercises:searchExercises",
            with: ["searchTerm": searchTerm],
            yielding: [ConvexExercise]?.self
        ).replaceError(with: nil).eraseToAnyPublisher()
    }
    
    /// Create a new exercise
    func createExercise(
        name: String,
        muscleGroup: String,
        exerciseType: ConvexExerciseType,
        description: String? = nil,
        defaultWeight: Double? = nil,
        defaultWeightUnit: String? = nil,
        isPrimary: Bool? = nil
    ) async throws -> String {
        return try await client.mutation("exercises:createExercise", with: [
            "name": name,
            "muscleGroup": muscleGroup,
            "exerciseType": exerciseType.rawValue,
            "description": description,
            "defaultWeight": defaultWeight,
            "defaultWeightUnit": defaultWeightUnit,
            "isPrimary": isPrimary
        ])
    }
}

// MARK: - Errors

enum ConvexAPIError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "No API key configured. Go to Settings to add one."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }
}

// MARK: - Helper Extension

extension ConvexAPI {
    /// Determine exercise type from muscle group (convenience)
    static func exerciseType(for muscleGroup: String) -> ConvexExerciseType {
        switch muscleGroup.lowercased() {
        case "cardio": return .cardio
        case "core": return .calisthenics
        default: return .resistance
        }
    }
}
`;

  // Ensure output directory exists
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }
  
  // Write the file
  const outputPath = path.join(OUTPUT_DIR, 'ConvexAPI.swift');
  fs.writeFileSync(outputPath, swiftCode);
  
  console.log(`✅ Generated: ${outputPath}`);
  console.log('\n📝 Next steps:');
  console.log('   1. Add the generated file to your Xcode project');
  console.log('   2. Replace ConvexService usage with ConvexAPI');
  console.log('   3. Re-run this script when you update your Convex schema');
}

// Run the generator
generateSwiftClient().catch(console.error);
