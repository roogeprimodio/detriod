import React, { useState, useEffect } from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { StyleSheet, View } from 'react-native';
import { SafeAreaProvider } from "react-native-safe-area-context";
import { Toaster } from 'sonner-native';
import { MaterialIcons, FontAwesome5, Ionicons } from '@expo/vector-icons';

// Auth Screens
import SplashScreen from './screens/auth/SplashScreen';
import LoginScreen from './screens/auth/LoginScreen';
import SignupScreen from './screens/auth/SignupScreen';

// Main Screens
import HomeScreen from "./screens/HomeScreen";
import GameSelectionScreen from './screens/GameSelectionScreen';
import TournamentListScreen from './screens/tournament/TournamentListScreen';
import TournamentDetailsScreen from './screens/tournament/TournamentDetailsScreen';
import RegisterScreen from './screens/tournament/RegisterScreen';
import RegisteredMatchesScreen from './screens/matches/RegisteredMatchesScreen';
import MatchDetailsScreen from './screens/matches/MatchDetailsScreen';
import MatchScheduleScreen from './screens/matches/MatchScheduleScreen';
import LobbyDetailsScreen from './screens/matches/LobbyDetailsScreen';
import LiveMatchScreen from './screens/matches/LiveMatchScreen';
import LeaderboardScreen from './screens/matches/LeaderboardScreen';
import TournamentResultsScreen from './screens/matches/TournamentResultsScreen';
import ProfileScreen from './screens/profile/ProfileScreen';
import WalletScreen from './screens/profile/WalletScreen';
import WithdrawalScreen from './screens/profile/WithdrawalScreen';
import TeamsScreen from './screens/teams/TeamsScreen';
import TeamManagementScreen from './screens/teams/TeamManagementScreen';
import CreateTeamScreen from './screens/teams/CreateTeamScreen';
import TeamChatScreen from './screens/teams/TeamChatScreen';
import StoreScreen from './screens/store/StoreScreen';
import AdminDashboardScreen from './screens/admin/AdminDashboardScreen';
import TournamentManagementScreen from './screens/admin/TournamentManagementScreen';
import UserManagementScreen from './screens/admin/UserManagementScreen';
import AdvertisementScreen from './screens/admin/AdvertisementScreen';
import SettingsScreen from './screens/settings/SettingsScreen';
import NotificationsScreen from './screens/settings/NotificationsScreen';
import PrivacySecurityScreen from './screens/settings/PrivacySecurityScreen';
import HelpSupportScreen from './screens/settings/HelpSupportScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

// Auth Navigator
function AuthStack() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="Splash" component={SplashScreen} />
      <Stack.Screen name="Login" component={LoginScreen} />
      <Stack.Screen name="Signup" component={SignupScreen} />
    </Stack.Navigator>
  );
}

// Home Stack
function HomeStackNavigator() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="HomeScreen" component={HomeScreen} />
      <Stack.Screen name="GameSelection" component={GameSelectionScreen} />
      <Stack.Screen name="TournamentList" component={TournamentListScreen} />
      <Stack.Screen name="TournamentDetails" component={TournamentDetailsScreen} />
      <Stack.Screen name="Register" component={RegisterScreen} />
      <Stack.Screen name="MatchDetails" component={MatchDetailsScreen} />
    </Stack.Navigator>
  );
}

// Matches Stack
function MatchesStackNavigator() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="RegisteredMatches" component={RegisteredMatchesScreen} />
      <Stack.Screen name="MatchDetails" component={MatchDetailsScreen} />
      <Stack.Screen name="MatchSchedule" component={MatchScheduleScreen} />
      <Stack.Screen name="LobbyDetails" component={LobbyDetailsScreen} />
      <Stack.Screen name="LiveMatch" component={LiveMatchScreen} />
      <Stack.Screen name="Leaderboard" component={LeaderboardScreen} />
      <Stack.Screen name="TournamentResults" component={TournamentResultsScreen} />
    </Stack.Navigator>
  );
}

// Teams Stack
function TeamsStackNavigator() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="TeamsMain" component={TeamsScreen} />
      <Stack.Screen name="TeamManagement" component={TeamManagementScreen} />
      <Stack.Screen name="CreateTeam" component={CreateTeamScreen} />
      <Stack.Screen name="TeamChat" component={TeamChatScreen} />
    </Stack.Navigator>
  );
}

// Profile Stack
function ProfileStackNavigator() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="ProfileMain" component={ProfileScreen} />
      <Stack.Screen name="Wallet" component={WalletScreen} />
      <Stack.Screen name="Withdrawal" component={WithdrawalScreen} />
      <Stack.Screen name="Settings" component={SettingsScreen} />
      <Stack.Screen name="Notifications" component={NotificationsScreen} />
      <Stack.Screen name="PrivacySecurity" component={PrivacySecurityScreen} />
      <Stack.Screen name="HelpSupport" component={HelpSupportScreen} />
    </Stack.Navigator>
  );
}

// Admin Stack
function AdminStackNavigator() {
  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      <Stack.Screen name="AdminDashboard" component={AdminDashboardScreen} />
      <Stack.Screen name="TournamentManagement" component={TournamentManagementScreen} />
      <Stack.Screen name="UserManagement" component={UserManagementScreen} />
      <Stack.Screen name="Advertisement" component={AdvertisementScreen} />
    </Stack.Navigator>
  );
}

// Main Tab Navigator
function MainTabNavigator() {
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#4361ee',
        tabBarInactiveTintColor: '#8d99ae',
        tabBarStyle: {
          paddingBottom: 5,
          paddingTop: 5,
          height: 60,
        },
      }}
    >
      <Tab.Screen 
        name="Home" 
        component={HomeStackNavigator} 
        options={{
          tabBarIcon: ({ color, size }) => (
            <Ionicons name="home" size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen 
        name="Matches" 
        component={MatchesStackNavigator} 
        options={{
          tabBarIcon: ({ color, size }) => (
            <MaterialIcons name="sports-esports" size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen 
        name="Teams" 
        component={TeamsStackNavigator} 
        options={{
          tabBarIcon: ({ color, size }) => (
            <FontAwesome5 name="users" size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen 
        name="Store" 
        component={StoreScreen} 
        options={{
          tabBarIcon: ({ color, size }) => (
            <FontAwesome5 name="shopping-cart" size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen 
        name="Profile" 
        component={ProfileStackNavigator} 
        options={{
          tabBarIcon: ({ color, size }) => (
            <FontAwesome5 name="user" size={size} color={color} />
          ),
        }}
      />
    </Tab.Navigator>
  );
}

// Root Stack
function RootStack() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);
  
  // This would typically connect to Firebase Auth
  useEffect(() => {
    // Simulating authentication check
    setTimeout(() => {
      setIsAuthenticated(false);
    }, 2000);
  }, []);

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {!isAuthenticated ? (
        <Stack.Screen name="Auth" component={AuthStack} />
      ) : isAdmin ? (
        <Stack.Screen name="AdminStack" component={AdminStackNavigator} />
      ) : (
        <Stack.Screen name="MainApp" component={MainTabNavigator} />
      )}
    </Stack.Navigator>
  );
}

export default function App() {
  return (
    <SafeAreaProvider style={styles.container}>
      <Toaster />
      <NavigationContainer>
        <RootStack />
      </NavigationContainer>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1
  }
});
